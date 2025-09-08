#!/bin/sh

# cpu : 4
# memory : 8g
# v_ram : 500m

KEXA_VERSION=
NODE_TLS_REJECT_UNAUTHORIZED=
MEMORY=
CPUS=
V_RAM=

# if NODE_TLS_REJECT_UNAUTHORIZED is not set, default to 0
if [ -z "$NODE_TLS_REJECT_UNAUTHORIZED" ]; then
    echo "NODE_TLS_REJECT_UNAUTHORIZED has not been set, setting to 0."
    NODE_TLS_REJECT_UNAUTHORIZED=0
fi

# if version is not set, default to latest
if [ -z "$KEXA_VERSION" ]; then
    echo "KEXA_VERSION has not been set, setting to latest version."
    KEXA_VERSION="latest"
fi

# if memory is not set, default to 8g
if [ -z "$MEMORY" ]; then
    echo "MEMORY has not been set, setting to default 8g."
    MEMORY="8g"
fi

# if cpus is not set, default to 4
if [ -z "$CPUS" ]; then
    echo "CPUS has not been set, setting to default 4."
    CPUS="4"
fi

# if v_ram is not set, default to 500m
if [ -z "$V_RAM" ]; then
    echo "V_RAM has not been set, setting to default 500m."
    V_RAM="500m"
fi

KEXA_IMAGE="kexa/kexa:$KEXA_VERSION"
CRONICLE_TRIGGER_ID_FROM=
INIT_PREMIUM_MODE=

# if Cronicle job Id is not set, exit
if [ -z "$CRONICLE_TRIGGER_ID_FROM" ]; then
    echo "CRONICLE_TRIGGER_ID_FROM is not set, should be sent by frontend, exiting."
    exit 1
fi

CONTAINER_NAME="kexa-persistent-$CRONICLE_TRIGGER_ID_FROM"

# always clean up container and temp files on script exit
trap 'docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true; rm -rf tmp_env_file >/dev/null 2>&1 || true' EXIT

echo "Kexa version: $KEXA_VERSION"
echo "Container name: $CONTAINER_NAME"

handle_error() {
    echo "Error occurred at line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# remove any old container (running or stopped) with the same name
if docker ps -a -q -f name=$CONTAINER_NAME | grep -q .; then
    echo "Removing old container $CONTAINER_NAME..."
    docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
fi

echo "Creating persistent Kexa container..."

# pull if it doesn't exist locally
if ! docker image inspect $KEXA_IMAGE >/dev/null 2>&1; then
    echo "Pulling the Kexa image..."
    docker pull $KEXA_IMAGE || {
        echo "Failed to pull image $KEXA_IMAGE"
        exit 1
    }
fi

CONTAINER_ID=$(docker run -d \
    --name $CONTAINER_NAME \
    --network=host \
    --tmpfs /tmp:rw,noexec,nosuid,size=$V_RAM \
    --memory=$MEMORY \
    --cpus=$CPUS \
    $KEXA_IMAGE tail -f /dev/null)

docker exec $CONTAINER_ID sh -c "
    mkdir -p /app/config /app/Kexa/config
    printf '{}' > /app/config/headers.json
    ln -sf /app/config/headers.json /app/Kexa/config/headers.json
"


REQUIRED_VARS="KEXA_API_TOKEN KEXA_API_TOKEN_NAME KEXA_API_URL CRONICLE_TRIGGER_ID_FROM"

echo "Waiting for required environment variables..."
while true; do
    all_set=true
    for var in $REQUIRED_VARS; do
        eval "value=\${$var}"
        if [ -z "$value" ]; then
            all_set=false
            break
        fi
    done
    if [ "$all_set" = true ]; then
        echo "All environment variables are set!"
        break
    fi
    sleep 1
done


ENV_VARS=""
ENV_VARS="$ENV_VARS -e NODE_TLS_REJECT_UNAUTHORIZED=${NODE_TLS_REJECT_UNAUTHORIZED}"
ENV_VARS="$ENV_VARS -e INTERFACE_CONFIGURATION_ENABLED=true"
ENV_VARS="$ENV_VARS -e API_SECRET_KEY=${API_SECRET_KEY}"
ENV_VARS="$ENV_VARS -e API_SECRET_IV=${API_SECRET_IV}"
ENV_VARS="$ENV_VARS -e API_ENCRYPTION_METHOD=${API_ENCRYPTION_METHOD:-AES-256-CBC}"
ENV_VARS="$ENV_VARS -e KEXA_API_URL=${KEXA_API_URL}"
ENV_VARS="$ENV_VARS -e KEXA_API_TOKEN_NAME=${KEXA_API_TOKEN_NAME}"
ENV_VARS="$ENV_VARS -e KEXA_API_TOKEN=${KEXA_API_TOKEN}"
ENV_VARS="$ENV_VARS -e CRONICLE_TRIGGER_ID_FROM=${CRONICLE_TRIGGER_ID_FROM}"
ENV_VARS="$ENV_VARS -e INIT_PREMIUM_MODE=${INIT_PREMIUM_MODE:-false}"

echo "Running Kexa in persistent container..."

docker exec $ENV_VARS $CONTAINER_ID sh -c "cd /app && exec bun run Kexa/main.ts" || {
    echo "Failed to run Kexa"
    handle_error $LINENO
}

echo "Kexa executed successfully"

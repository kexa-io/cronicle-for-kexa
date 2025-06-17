#!/bin/sh

KEXA_VERSION=
MEMORY="8g"
CPUS="4"
V_RAM="500m"

# if version is not set, default to latest
if [ -z "$KEXA_VERSION" ]; then
    echo "KEXA_VERSION has not been set, setting to latest version."
    KEXA_VERSION="latest"
fi

# if memory is not set, default to 2g
if [ -z "$MEMORY" ]; then
    echo "MEMORY has not been set, setting to default 2g."
    MEMORY="6g"
fi

# if cpus is not set, default to 2
if [ -z "$CPUS" ]; then
    echo "CPUS has not been set, setting to default 2."
    CPUS="4"
fi

KEXA_IMAGE="innovtech/kexa-dev:$KEXA_VERSION"
CRONICLE_TRIGGER_ID_FROM=
INIT_PREMIUM_MODE=

# if Cronicle job Id is not set, exit
if [ -z "$CRONICLE_TRIGGER_ID_FROM" ]; then
    echo "CRONICLE_TRIGGER_ID_FROM is not set, should be sent by frontend, exiting."
    exit 1
fi

CONTAINER_NAME="kexa-persistent-$CRONICLE_TRIGGER_ID_FROM-$(date +%s)"

echo "Container name: $CRONICLE_JOB_ID"

handle_error() {
    echo "Error occurred at line $1"
    rm -rf tmp_env_file >/dev/null 2>&1
    exit 1
}

trap 'handle_error $LINENO' ERR

# check if persistent container exist
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    echo "Using existing Kexa container..."
    CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME)
else
    echo "Creating persistent Kexa container..."

    # pull if don't exist locally
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
fi

ENV_VARS=""
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
docker exec $ENV_VARS $CONTAINER_ID sh -c "cd /app && exec bun run Kexa/index.ts" || {
    echo "Failed to run Kexa"
    handle_error $LINENO
}

echo "Cleaning up..."
docker rm -f $CONTAINER_ID >/dev/null 2>&1 || true
rm -rf tmp_env_file >/dev/null 2>&1 || true

echo "Kexa executed successfully"

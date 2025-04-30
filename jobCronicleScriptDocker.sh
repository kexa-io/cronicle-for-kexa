#!/bin/sh

export NODE_OPTIONS="--max-old-space-size=4096"

KEXA_IMAGE="innovtech/kexabun:debugging"

handle_error() {
  echo "Error occurred at line $1"
  rm -rf tmp_env_file >/dev/null 2>&1
  exit 1
}

trap 'handle_error $LINENO' ERR

rm -rf tmp_env_file >/dev/null 2>&1 || true

echo "Pulling the Kexa image..."
docker pull $KEXA_IMAGE || { echo "Failed to pull image $KEXA_IMAGE"; exit 1; }

echo "Creating environment file..."
touch tmp_env_file

echo INTERFACE_CONFIGURATION_ENABLED="${INTERFACE_CONFIGURATION_ENABLED:-true}" >> tmp_env_file
echo API_SECRET_KEY="${API_SECRET_KEY}" >> tmp_env_file
echo API_SECRET_IV="${API_SECRET_IV}" >> tmp_env_file
echo API_ENCRYPTION_METHOD="${API_ENCRYPTION_METHOD:-AES-256-CBC}" >> tmp_env_file
echo KEXA_API_URL="${KEXA_API_URL}" >> tmp_env_file
echo KEXA_API_TOKEN_NAME="${KEXA_API_TOKEN_NAME}" >> tmp_env_file
echo KEXA_API_TOKEN="${KEXA_API_TOKEN}" >> tmp_env_file

echo "Running Kexa..."
docker run --rm \
    --network=host \
    --env-file tmp_env_file \
    --memory=2g \
    --memory-swap=3g \
    --pids-limit=0 \
    -v "$(pwd)/kexa_data:/usr/src/app/data" \
    -v "$(pwd)/kexa_config:/usr/src/app/config" \
    $KEXA_IMAGE sh -c "
        chmod -R 777 /usr/src/app
        
        mkdir -p /usr/src/app/config
        mkdir -p /usr/src/app/Kexa/config
        
        echo '{}' > /usr/src/app/config/headers.json
        echo '{}' > /usr/src/app/Kexa/config/headers.json
        
        ln -sf /usr/src/app/config/headers.json /usr/src/app/Kexa/config/headers.json
        
        find /usr/src/app -type d -exec chmod 777 {} \;
        find /usr/src/app -type f -exec chmod 666 {} \;

        cd /usr/src/app && bun run Kexa/index.ts
    " || { echo "Failed to run Kexa"; handle_error $LINENO; }

echo "Cleaning up..."
rm -rf tmp_env_file
echo "Kexa executed successfully"
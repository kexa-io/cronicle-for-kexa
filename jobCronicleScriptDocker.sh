# #!/bin/sh

# # docker pull innovtech/kexabun:latest

# echo "Testing API connectivity..."
# echo "KEXA_API_URL: ${KEXA_API_URL}"
# echo "NAMESPACE: ${KUBE_APP_NAME}"
# curl -v "http://${KUBE_APP_NAME}-api-svc:4012" || echo "Service name only failed"
# curl -v "http://${KUBE_APP_NAME}-api-svc.kexa:4012" || echo "Service with namespace failed"

# TMP_KEXA_IMG="temp_image"
# HOST_CONFIG_FOLDER="tmpconfig"
# KUBERNETES_CONFIG_FOLDER="kubernetesconfigurations"



# SHARED_DIR="/app/shared/$HOST_CONFIG_FOLDER/rules"

# mkdir /tmp/$KUBERNETES_CONFIG_FOLDER

# if [ -d "/app/$KUBERNETES_CONFIG_FOLDER" ] && [ "$(ls -A /app/$KUBERNETES_CONFIG_FOLDER 2>/dev/null)" ]; then
#     for file in /app/$KUBERNETES_CONFIG_FOLDER/*; do
#         if [ -f "$file" ]; then
#             filename=$(basename "$file")
#             cat "$file" > "/tmp/$KUBERNETES_CONFIG_FOLDER/$filename"
#         fi
#     done
# else
#     echo "No Kubernetes configuration files found or directory is empty"
# fi

# if [ "$(docker ps -aq -f name=temp_container)" ]; then
#     docker stop temp_container
#     docker rm temp_container
# fi

# if [ "$(docker images -q $TMP_KEXA_IMG 2> /dev/null)" ]; then
#     docker rmi $TMP_KEXA_IMG
# fi

# rm -rf tmp_env_file

# echo "Pulling latest image and creating temp container..."
# docker run -d --name temp_container innovtech/kexabun:latest tail -f /dev/null
# if [ $? -ne 0 ]; then
#     echo "Failed to create temp container."
#     exit 1
# fi

# echo "Created temp container."
# echo "Copying shared directory to temp container..."
# docker cp "$SHARED_DIR" temp_container:/app/
# docker cp /app/config temp_container:/app/
# echo "INTERFACE_CONFIGURATION_ENABLED='true'" >> /app/.env
# docker cp /app/.env temp_container:/app/.env

# if [ "$(ls -A /tmp/$KUBERNETES_CONFIG_FOLDER 2>/dev/null)" ]; then
#     docker cp /tmp/$KUBERNETES_CONFIG_FOLDER/. temp_container:/app/
# fi

# docker commit temp_container $TMP_KEXA_IMG

# printenv | grep -E '^[A-Z_][A-Z0-9_]*=.*$' | grep -v ' ' > tmp_env_file

# echo "Running kexa..."

# docker run --rm \
#     --network=host \
#     --env-file tmp_env_file \
#     $TMP_KEXA_IMG sh -c "bun run Kexa/index.ts"

# rm -rf tmp_env_file

# rm -rf /tmp/$KUBERNETES_CONFIG_FOLDER
# rmdir /tmp/$KUBERNETES_CONFIG_FOLDER 2>/dev/null || true


# if [ "$(docker ps -aq -f name=temp_container)" ]; then
#     docker stop temp_container
#     docker rm temp_container
# fi

# docker rmi $TMP_KEXA_IMG

#!/bin/sh

TMP_KEXA_IMG="temp_image"

if [ "$(docker ps -aq -f name=temp_container)" ]; then
    docker stop temp_container
    docker rm temp_container
fi

if [ "$(docker images -q $TMP_KEXA_IMG 2> /dev/null)" ]; then
    docker rmi $TMP_KEXA_IMG
fi

rm -rf tmp_env_file

docker run -d --name temp_container innovtech/kexabun:latest tail -f /dev/null
if [ $? -ne 0 ]; then
    echo "Failed to create temp container."
    exit 1
fi

echo "Creating temporary .env file"
mkdir -p /tmp/kexa
echo "INTERFACE_CONFIGURATION_ENABLED='true'" > /tmp/kexa/.env

docker exec temp_container sh -c "mkdir -p /app"
docker cp /tmp/kexa/.env temp_container:/app/.env
docker exec temp_container sh -c "if [ -f /app/.env ]; then echo '.env file exists in container'; cat /app/.env | grep INTERFACE_CONFIGURATION_ENABLED && echo 'Configuration is set correctly'; else echo 'ERROR: .env file was not copied'; exit 1; fi"

if [ $? -ne 0 ]; then
    echo "Failed to verify .env file in container. Aborting."
    docker stop temp_container
    docker rm temp_container
    exit 1
fi

docker commit temp_container $TMP_KEXA_IMG
printenv | grep -E '^[A-Z_][A-Z0-9_]*=.*$' | grep -v ' ' > tmp_env_file
echo "Running kexa..."

docker run --rm \
    --network=host \
    --env-file tmp_env_file \
    $TMP_KEXA_IMG sh -c "bun run Kexa/index.ts"

rm -rf tmp_env_file
rm -rf /tmp/kexa
if [ "$(docker ps -aq -f name=temp_container)" ]; then
    docker stop temp_container
    docker rm temp_container
fi
docker rmi $TMP_KEXA_IMG
# Cronicle For Kexa

### Related docker hub repository :

- Dockerfile.saas: https://hub.docker.com/repository/docker/innovtech/kexa-cronicle

- Dockerfile.local: https://hub.docker.com/repository/docker/innovtech/kexa-cronicle-local

### To use the local image:

```bash
docker run -d --name cronicle-dind --privileged -p 3012:3012 -e API_KEY="cronicleApiKey" innovtech/kexa-cronicle-local:latest
```
- cronicleApiKey: Choose an api key you will set in the previous command, in the API .env file and in the Frontend config file, this will be used to connect everything together.
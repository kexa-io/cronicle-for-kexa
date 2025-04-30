# Cronicle For Kexa

### Related docker hub repository :

- Dockerfile.saas: https://hub.docker.com/repository/docker/innovtech/kexa-cronicle

- Dockerfile.local: https://hub.docker.com/repository/docker/innovtech/kexa-cronicle-local

### Cronicle for Kexa local & SaaS run

**Docker**
```bash
docker run -d --name cronicle-dind-kexa -p 3012:3012 -e API_KEY=your_cronicle_api_key -e INTERFACE_CONFIGURATION_ENABLED=true -e API_SECRET_KEY=secretKey -e API_SECRET_IV=secretIV -e API_ENCRYPTION_METHOD=AES-256-CBC -e KEXA_API_URL=http://host.docker.internal:4012/api -e KEXA_API_TOKEN_NAME=your_kexa_default_token_name -e KEXA_API_TOKEN=your_kexa_default_token -v /var/run/docker.sock:/var/run/docker.sock innovtech/kexa-cronicle-local:latest
```

**Docker Compose**
```yaml
version: '2.35.0'
services:
  cronicle:
    image: innovtech/kexa-cronicle:latest
    container_name: cronicle-dind-kexa
    ports:
      - "3012:3012"
    environment:
      - API_KEY=your_cronicle_api_key # CRONICLE_API_KEY in Kexa API
      - INTERFACE_CONFIGURATION_ENABLED=true # true for saas
      - API_SECRET_KEY=secretKey # same as the one in Kexa API
      - API_SECRET_IV=secretIV # same as the one in Kexa API
      - API_ENCRYPTION_METHOD=AES-256-CBC # same as the one in Kexa API
      - KEXA_API_URL=http://host.docker.internal:4012/api
      - KEXA_API_TOKEN_NAME=your_kexa_default_token_name # DEFAULT_API_KEY_NAME in Kexa API
      - KEXA_API_TOKEN=your_kexa_default_token # DEFAULT_API_KEY in Kexa API
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```
- cronicleApiKey: Choose an api key you will set in the previous command, in the API .env file and in the Frontend config file, this will be used to connect everything together.
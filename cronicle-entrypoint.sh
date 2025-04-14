#!/bin/sh
dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 &
sleep 7

if [ ! -z "$API_KEY" ]; then
  cd /opt/cronicle
  if [ ! -f "/opt/cronicle/data/global/users.json" ]; then
    echo "Adding custom API key to setup.json..."
    CURRENT_TIME=$(date +%s)
    echo "Debug: Original setup.json contents:"
    cat /opt/cronicle/conf/setup.json
    sed -i '/"listCreate", "global\/api_keys"/a\
    ,[ "listPush", "global/api_keys", {\
      "privileges": {\
        "admin": 1,\
        "create_events": 1,\
        "edit_events": 1,\
        "delete_events": 1,\
        "run_events": 1,\
        "abort_events": 1,\
        "state_update": 1\
      },\
      "active": "1",\
      "title": "Container init API Key",\
      "description": "API Key from environment variable",\
      "id": "'$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -n 1)'",\
      "key": "'$API_KEY'",\
      "username": "admin",\
      "modified": "'$CURRENT_TIME'",\
      "created": "'$CURRENT_TIME'"\
    } ]' /opt/cronicle/conf/setup.json
    echo "Debug: Modified setup.json contents:"
    cat /opt/cronicle/conf/setup.json
    echo "Setup.json has been updated with the custom API key"
    rm -rf /opt/cronicle/data/*
    echo "Running setup to initialize storage..."
    /opt/cronicle/bin/control.sh setup
  else
    echo "Storage already initialized, skipping API key setup"
  fi
fi

cd /opt/cronicle && ./bin/control.sh start
tail -f /dev/null
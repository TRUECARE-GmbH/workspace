# Manuelle Installation (docker native, linux)
## Registrierung der Umgebungsvariablen
``$ export $(grep -v '^#' production.env | xargs)``

## Installation mongodb
``docker run -v mongo-db:/data/db -v mongo-config:/data/configdb -h workspace-mongo -e MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME} -e MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD} mongo:latest``

## Installation Linnea
``docker run -h workspace-linnea --link mongo:workspace-mongo -e LICENSEES=https://{0}.{$DOMAIN} -e WORKSPACE_DB_CONNECTIONSTRING=mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@workspace-mongo:27017 -e WORKSPACE_MASTERPASSWORD=${MASTERPASSWORD} registry.workspace.pm/workspace/linnea:latest``

## Installation Iris
``docker run -h workspace-iris --link mongo:workspace-mongo -e AUTH_DB_CONNECTIONSTRING=mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@workspace-mongo:27017 -e AUTH_DOMAIN=${AUTH_DOMAIN} -e AUTH_DOMAIN_PORT=${AUTH_DOMAIN_PORT} -e AUTH_AUTHDOMAIN=${AUTH_AUTHDOMAIN} -e ENCRYPTION_KEY=${ENCRYPTIONKEY} -e SCHEME=${SCHEME} registry.workspace.pm/workspace/iris:latest``

## Installation workspace serverside
``docker run -v tenantdata:/app/wwwroot/tenantdata/ -h workspace --link mongo:workspace-mongo -e WORKSPACE_AUTH_SERVER=https://auth.${AUTH_DOMAIN_PORT} -e WORKSPACE_DB_CONNECTIONSTRING=mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@workspace-mongo:27017 -e WORKSPACE_DOMAIN={$DOMAIN} -e WORKSPACE_ENCRYPTION_KEY=${ENCRYPTIONKEY} registry.workspace.pm/workspace/serverside:latest``

## Installation Reverse Proxy
``docker run -v ./nginx/nginx.conf:/etc/nginx/nginx.conf -v ./nginx/public.crt:/var/lib/wsdata/nginx/public.crt -v ./nginx/private.key:/var/lib/wsdata/nginx/private.key --link linnea:workspace-linnea --link iris:workspace-iris --link serverside:workspace -p ${PORT_HTTP}:80 -p ${PORT_HTTPS}:443 nginx:latest``
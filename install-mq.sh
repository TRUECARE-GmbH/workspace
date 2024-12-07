#!/bin/bash

# Variables
SERVICE1_NAME="automate-service"
SERVICE1_IMAGE="registry.workspace.pm/workspace/automate:latest"
SERVICE1_PORT="18080:80"
WS_CONFIG="workspace-prod-v2"
SERVICE1_CONFIG_TARGET="/app/appsettings.json"

SERVICE2_NAME="rabbitmq-service"
SERVICE2_IMAGE="rabbitmq:3-management"
SERVICE2_PORTS="15672:15672,5672:5672"
RABBITMQ_USER="root"

function get_config_value() {
    local config_name=$1
    local key=$2

    config_content=$(docker config inspect --format '{{json .Spec.Data}}' "$config_name" | jq -r '. | @base64d')
    if [[ $? -ne 0 ]]; then
        echo "Error reading config $config_name"
        exit 1
    fi

    # Extract value from JSON
    echo "$config_content" | jq -r ".$key"
}

function install_services() {
    echo "Installing dependencies"
    apt install jq -y

    echo "Creating and starting services..."

    # Read RABBITMQ_PASS from config
    RABBITMQ_PASS=$(get_config_value "$WS_CONFIG" "MASTERPASSWORD")
    if [[ -z "$RABBITMQ_PASS" ]]; then
        echo "MASTERPASSWORD could not be read from the config"
        exit 1
    fi

    # Service 1: Automate
    docker service create \
        --name $SERVICE1_NAME \
        --publish $SERVICE1_PORT \
        --config source=$SERVICE1_CONFIG,target=$SERVICE1_CONFIG_TARGET \
        $SERVICE1_IMAGE

    # Service 2: RabbitMQ
    docker service create \
        --name $SERVICE2_NAME \
        --publish $SERVICE2_PORTS \
        --env RABBITMQ_DEFAULT_USER=$RABBITMQ_USER \
        --env RABBITMQ_DEFAULT_PASS=$RABBITMQ_PASS \
        $SERVICE2_IMAGE
}

function update_services() {
    echo "Updating services..."

    # Read RABBITMQ_PASS from config
    RABBITMQ_PASS=$(get_config_value "$WS_CONFIG" "MASTERPASSWORD")
    if [[ -z "$RABBITMQ_PASS" ]]; then
        echo "MASTERPASSWORD could not be read from the config"
        exit 1
    fi

    # Service 1: Automate
    docker service update \
        --image $SERVICE1_IMAGE \
        $SERVICE1_NAME

    # Service 2: RabbitMQ
    docker service update \
        --image $SERVICE2_IMAGE \
        --env-add RABBITMQ_DEFAULT_PASS=$RABBITMQ_PASS \
        $SERVICE2_NAME
}

function main() {
    case "$1" in
        install)
            install_services
            ;;
        update)
            update_services
            ;;
        *)
            echo "Usage: $0 {install|update}"
            exit 1
            ;;
    esac
}

# Start script
main "$@"

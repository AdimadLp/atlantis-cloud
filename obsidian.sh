#!/bin/bash

# Obsidian CouchDB Docker Compose wrapper script
# This script runs the Docker Compose file from the correct location with the root .env file

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
COMPOSE_FILE="$SCRIPT_DIR/notes/obsidian/docker-compose.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please create it from the template:"
    echo "cp notes/obsidian/.env.example .env"
    exit 1
fi

# Check if docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: docker-compose.yaml not found at $COMPOSE_FILE"
    exit 1
fi

# Run docker-compose with the specified files
echo "Running Docker Compose for Obsidian CouchDB..."
echo "Compose file: $COMPOSE_FILE"
echo "Environment file: $ENV_FILE"
echo ""

docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"

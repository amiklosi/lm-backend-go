#!/bin/bash

# Exit on any error
set -e

# Check if image tags are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <app-image-tag> <mysql-image-tag>"
    echo "Example: $0 ghcr.io/amiklosi/lm-backend-go:latest ghcr.io/amiklosi/lm-backend-go-mysql:latest"
    exit 1
fi

APP_IMAGE="$1"
MYSQL_IMAGE="$2"

echo "Deploying with images:"
echo "  App: $APP_IMAGE"
echo "  MySQL: $MYSQL_IMAGE"

# Check if required environment variables are set
if [ -z "$PORTAINER_URL" ]; then
    echo "Error: PORTAINER_URL environment variable is not set"
    exit 1
fi

if [ -z "$PORTAINER_USERNAME" ]; then
    echo "Error: PORTAINER_USERNAME environment variable is not set"
    exit 1
fi

if [ -z "$PORTAINER_PASSWORD" ]; then
    echo "Error: PORTAINER_PASSWORD environment variable is not set"
    exit 1
fi

if [ -z "$STACK_ID" ]; then
    echo "Error: STACK_ID environment variable is not set"
    exit 1
fi

if [ -z "$ENDPOINT_ID" ]; then
    echo "Error: ENDPOINT_ID environment variable is not set"
    exit 1
fi

echo "Starting deployment to Portainer..."

# Get authentication token
echo "Authenticating with Portainer..."
TOKEN=$(curl -s -X POST "$PORTAINER_URL/api/auth" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$PORTAINER_USERNAME\",\"Password\":\"$PORTAINER_PASSWORD\"}" | jq -r '.jwt')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "Error: Failed to authenticate with Portainer"
    exit 1
fi

echo "Authentication successful"

# Create a temporary compose file with the specific image tags
echo "Creating deployment compose file..."
TEMP_COMPOSE=$(mktemp)
cat docker-compose.prod.yml | \
  sed "s|image: ghcr.io/amiklosi/lm-backend-go:latest|image: $APP_IMAGE|g" | \
  sed "s|image: ghcr.io/amiklosi/lm-backend-go-mysql:latest|image: $MYSQL_IMAGE|g" > "$TEMP_COMPOSE"

# Read the modified compose file
STACKFILE=$(cat "$TEMP_COMPOSE")

if [ -z "$STACKFILE" ]; then
    echo "Error: Could not read modified compose file"
    rm -f "$TEMP_COMPOSE"
    exit 1
fi

echo "Compose file updated with specific image tags"

# Update the stack
echo "Updating stack $STACK_ID..."
RESULT=$(curl -s -X PUT "$PORTAINER_URL/api/stacks/$STACK_ID?endpointId=$ENDPOINT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg stackfile "$STACKFILE" \
    '{
      env: [{"name":"BACKEND_IMAGE_TAG","value":"latest"}],
      prune: true,
      pullImage: true,
      stackFileContent: $stackfile
    }')")

# Clean up temporary file
rm -f "$TEMP_COMPOSE"

# Check if the update was successful
if echo "$RESULT" | jq -e '.Id' > /dev/null 2>&1; then
    echo "Stack updated successfully!"
    echo "Stack ID: $(echo "$RESULT" | jq -r '.Id')"
else
    echo "Error: Failed to update stack"
    echo "Response: $RESULT"
    exit 1
fi

echo "Deployment completed successfully!"

  
#!/bin/bash

# Exit on any error
set -e

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

# Read the compose file
echo "Reading docker-compose.prod.yml..."
STACKFILE=$(cat docker-compose.prod.yml)

if [ -z "$STACKFILE" ]; then
    echo "Error: Could not read docker-compose.prod.yml"
    exit 1
fi

echo "Compose file loaded successfully"

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

  
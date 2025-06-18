#!/bin/bash

# Add Go bin to PATH
export PATH=$PATH:~/go/bin

# Start database if not running
docker-compose up db -d

# Set environment variables
export DB_HOST=db
export DB_PORT=3306
export DB_USER=launchpad_user
export DB_PASSWORD=launchpad_password
export DB_NAME=launchpad_db

# Run Air for hot-reload
air -c .air.toml

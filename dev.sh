#!/bin/bash

# Add Go bin to PATH
export PATH=$PATH:~/go/bin

# Start database if not running
docker-compose -f docker-compose.dev.yml up -d


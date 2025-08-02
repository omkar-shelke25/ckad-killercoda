#!/bin/bash

# Check container is running
if ! docker ps --format '{{.Names}}' | grep -q "^my-nginx$"; then
  echo "❌ Container 'my-nginx' is not running."
  exit 1
fi

# Check web server output
response=$(curl -s http://localhost:8080)
if echo "$response" | grep -q "Welcome to Custom Nginx Container!"; then
  echo "✅ Web server is responding correctly."
  exit 0
else
  echo "❌ Web server output does not match expected content."
  exit 1
fi
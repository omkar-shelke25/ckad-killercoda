#!/bin/bash

# Check if the custom-nginx image exists
if ! docker image inspect custom-nginx >/dev/null 2>&1; then
  echo "ERROR: Docker image 'custom-nginx' not found."
  exit 1
fi

# Check if the my-nginx container is running
if ! docker ps --format '{{.Names}}' | grep -q '^my-nginx$'; then
  echo "ERROR: Container 'my-nginx' is not running."
  exit 1
fi

# Check if port 8080 is mapped to container port 80
if ! docker ps --format '{{.Ports}}' | grep -q '0.0.0.0:8080->80/tcp'; then
  echo "ERROR: Container 'my-nginx' is not mapping port 8080 to port 80."
  exit 1
fi

# Verify the content served by the container
if ! curl -s http://localhost:8080 | grep -q 'Welcome to My Custom Nginx Server'; then
  echo "ERROR: Custom index.html content not served at http://localhost:8080."
  exit 1
fi

# Check if the Dockerfile exists and uses the correct base image
if ! grep -q 'FROM nginx:1.27-alpine' ~/scenario/Dockerfile; then
  echo "ERROR: Dockerfile does not use nginx:1.27-alpine as the base image."
  exit 1
fi

echo "SUCCESS: All checks passed! The custom Nginx container is running correctly."
exit 0

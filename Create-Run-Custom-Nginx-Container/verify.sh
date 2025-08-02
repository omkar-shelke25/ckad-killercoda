#!/bin/bash

# Check if the custom-nginx image exists
if ! docker image inspect custom-nginx:latest >/dev/null 2>&1; then
  echo "ERROR: Docker image 'custom-nginx:latest' not found."
  echo "HINT: Ensure you ran 'docker build -t custom-nginx .' in the ~/scenario directory."
  exit 1
fi

# Check if the Dockerfile uses the correct base image
if [ -f ~/scenario/Dockerfile ] && ! grep -q 'FROM nginx:1.27-alpine' ~/scenario/Dockerfile; then
  echo "ERROR: Dockerfile does not use nginx:1.27-alpine as the base image."
  echo "HINT: Check the FROM instruction in your Dockerfile."
  exit 1
fi

# Check if index.html exists and contains the required content
if [ -f ~/scenario/index.html ] && ! grep -q 'Welcome to My Custom Nginx Server' ~/scenario/index.html; then
  echo "ERROR: index.html does not contain '<h1>Welcome to My Custom Nginx Server</h1>'."
  echo "HINT: Verify the content of your index.html file."
  exit 1
fi

# Check if the my-nginx container is running
if ! docker ps --format '{{.Names}}' | grep -q '^my-nginx$'; then
  echo "ERROR: Container 'my-nginx' is not running."
  echo "HINT: Run 'docker run -d --name my-nginx -p 8080:80 custom-nginx'."
  exit 1
fi

# Check if port 8080 is mapped to container port 80
if ! docker ps --format '{{.Ports}}' | grep -q '0.0.0.0:8080->80/tcp'; then
  echo "ERROR: Container 'my-nginx' is not mapping port 8080 to port 80."
  echo "HINT: Check the port mapping in your 'docker run' command."
  exit 1
fi

# Verify the content served by the container
if ! curl -s http://localhost:8080 | grep -q 'Welcome to My Custom Nginx Server'; then
  echo "ERROR: Custom index.html content not served at http://localhost:8080."
  echo "HINT: Use 'docker logs my-nginx' to troubleshoot the container."
  exit 1
fi

echo "SUCCESS: All checks passed! The custom Nginx container is running correctly."
exit 0

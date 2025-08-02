#!/bin/bash

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running or accessible."
  echo "HINT: Ensure Docker is installed and running in the environment."
  exit 1
fi

# Check if nginx:1.27-alpine is available
if ! docker image inspect nginx:1.27-alpine >/dev/null 2>&1; then
  echo "ERROR: Base image 'nginx:1.27-alpine' not found."
  echo "HINT: Run 'docker pull nginx:1.27-alpine' to pull the base image."
  echo "HINT: Check network connectivity with 'ping docker.io' or verify Docker Hub access."
  exit 1
fi

# Check if the custom-nginx:latest image exists
if ! docker image inspect custom-nginx:latest >/dev/null 2>&1; then
  echo "ERROR: Docker image 'custom-nginx:latest' not found."
  echo "HINT: Run 'docker build -t custom-nginx:latest .' in the ~/scenario directory."
  echo "HINT: Check 'docker images' to see if the image was created."
  echo "HINT: Ensure 'Dockerfile' and 'index.html' exist in ~/scenario (run 'ls ~/scenario')."
  echo "HINT: Click the 'Solution' button for the correct steps."
  exit 1
fi

# Check if the Dockerfile exists and uses the correct base image
if [ ! -f ~/scenario/Dockerfile ]; then
  echo "ERROR: Dockerfile not found in ~/scenario."
  echo "HINT: Create a Dockerfile in ~/scenario with 'FROM nginx:1.27-alpine'."
  echo "HINT: Click the 'Solution' button for the correct Dockerfile."
  exit 1
elif ! grep -q 'FROM nginx:1.27-alpine' ~/scenario/Dockerfile; then
  echo "ERROR: Dockerfile does not use nginx:1.27-alpine as the base image."
  echo "HINT: Update the FROM instruction in your Dockerfile."
  echo "HINT: Click the 'Solution' button for the correct Dockerfile."
  exit 1
fi

# Check if index.html exists
if [ ! -f ~/scenario/index.html ]; then
  echo "ERROR: index.html not found in ~/scenario."
  echo "HINT: The index.html file should be provided in ~/scenario. Check with 'ls ~/scenario'."
  exit 1
fi

# Check if the my-nginx container is running
if ! docker ps --format '{{.Names}}' | grep -q '^my-nginx$'; then
  echo "ERROR: Container 'my-nginx' is not running."
  echo "HINT: Run 'docker run -d --name my-nginx -p 8080:80 custom-nginx:latest'."
  echo "HINT: Check 'docker ps -a' to see if the container failed to start."
  echo "HINT: Click the 'Solution' button for the correct steps."
  exit 1
fi

# Check if port 8080 is mapped to container port 80
if ! docker ps --format '{{.Ports}}' | grep -q '0.0.0.0:8080->80/tcp'; then
  echo "ERROR: Container 'my-nginx' is not mapping port 8080 to port 80."
  echo "HINT: Verify the port mapping in 'docker run -p 8080:80'."
  echo "HINT: Click the 'Solution' button for the correct steps."
  exit 1
fi

# Verify the content served by the container
if ! curl -s http://localhost:8080 | grep -q 'Welcome to My Custom Nginx Server'; then
  echo "ERROR: Custom index.html content not served at http://localhost:8080."
  echo "HINT: Use 'docker logs my-nginx' to troubleshoot the container."
  echo "HINT: Click the 'Solution' button for the correct steps."
  exit 1
fi

echo "SUCCESS: All checks passed! The custom Nginx container is running correctly."
exit 0

#!/bin/bash
set -euo pipefail

echo "Setting up the environment..."

# Create the joker namespace
kubectl create namespace joker

# Create the /opt/course/20 directory
mkdir -p /opt/course/20

# Create the original joker-deployment YAML
cat <<'EOF' > /opt/course/20/joker-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: joker-deployment
  namespace: joker
spec:
  replicas: 2
  selector:
    matchLabels:
      app: joker
  template:
    metadata:
      labels:
        app: joker
    spec:
      containers:
      - name: joker-container
        image: public.ecr.aws/docker/library/busybox:latest
        command: ["sh", "-c"]
        args:
        - |
          echo "Joker application starting..."
          echo "User ID: $(id -u)"
          echo "Capabilities: $(cat /proc/self/status | grep Cap)"
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Joker is running..."
            sleep 30
          done
EOF

# Apply the deployment
kubectl apply -f /opt/course/20/joker-deployment.yaml

# Wait for the deployment to be ready
echo "Waiting for joker-deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/joker-deployment -n joker

echo "✅ Environment setup complete!"
echo "📁 Original deployment YAML available at: /opt/course/20/joker-deployment.yaml"
echo "🎯 Your task: Modify the deployment with security context and capabilities"

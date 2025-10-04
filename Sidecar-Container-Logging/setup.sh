#!/bin/bash
set -euo pipefail

echo "Setting up the environment..."

# Create the mercury namespace
kubectl create namespace mercury

# Create the /opt/course/16 directory
mkdir -p /opt/course/16

# Create the original cleaner deployment YAML
cat <<'EOF' > /opt/course/16/cleaner.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cleaner
  template:
    metadata:
      labels:
        app: cleaner
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      containers:
      - name: cleaner-con
        image: public.ecr.aws/docker/library/busybox:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log
        command: ["sh", "-c"]
        args:
        - |
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleaning data..." >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Found 42 records" >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: 3 records missing!" >> /var/log/cleaner.log
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Data cleanup completed" >> /var/log/cleaner.log
            sleep 10
          done
EOF

# Apply the deployment
kubectl apply -f /opt/course/16/cleaner.yaml

# Wait for the deployment to be ready
echo "Waiting for cleaner deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/cleaner -n mercury

echo "✅ Environment setup complete!"
echo "📁 Original deployment YAML available at: /opt/course/16/cleaner.yaml"
echo "🎯 Your task: Add a sidecar container to capture logs from cleaner.log"

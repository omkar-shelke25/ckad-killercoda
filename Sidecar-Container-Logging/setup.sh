#!/bin/bash
set -e

# Create the course directory
mkdir -p /opt/course/16

# Create the existing Deployment YAML as described in the scenario
cat > /opt/course/16/cleaner.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
  labels:
    app: cleaner
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
      containers:
      - name: cleaner-con
        image: busybox:1.31.0
        command: ['sh', '-c', 'while true; do echo "$(date): cleaning data" >> /tmp/cleaner.log; sleep 10; done']
        volumeMounts:
        - name: logs
          mountPath: /tmp
      volumes:
      - name: logs
        emptyDir: {}
EOF

# Create the namespace
kubectl create namespace mercury --dry-run=client -o yaml | kubectl apply -f -

# Apply the initial deployment
kubectl apply -f /opt/course/16/cleaner.yaml

# Create a new file for the student to modify
cp /opt/course/16/cleaner.yaml /opt/course/16/cleaner-new.yaml

echo "✅ Setup complete!"
echo "📁 Deployment YAML created at: /opt/course/16/cleaner.yaml"
echo "📝 Your working file: /opt/course/16/cleaner-new.yaml"
echo "🎯 Your task: Add a sidecar container 'logger-con' to process the logs"
echo ""
echo "💡 Hint: The main container writes to /tmp/cleaner.log"
echo "🔍 Use 'kubectl logs' with container name to see sidecar output"

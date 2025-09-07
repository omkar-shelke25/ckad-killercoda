#!/bin/bash
set -e

# Create the course directory
mkdir -p /opt/course/17

# Create the initial Deployment YAML with nginx but empty volume
cat > /opt/course/17/test-init-container.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: default
  labels:
    app: test-init-container
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-init-container
  template:
    metadata:
      labels:
        app: test-init-container
    spec:
      containers:
      - name: nginx
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: web-content
        emptyDir: {}
EOF

kubectl expose deploy/test-init-container --port 80 

echo "✅ Setup complete!"
echo "📁 Deployment YAML created at: /opt/course/17/test-init-container.yaml"
echo "🎯 Your task: Add an InitContainer to prepare content in the shared volume"

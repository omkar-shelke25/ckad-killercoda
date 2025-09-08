#!/bin/bash
set -e

# Create the course directory
mkdir -p /opt/course/17

cat > 1.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: test-init-container
  name: test-init-container
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: test-init-container
status:
  loadBalancer: {}
EOF


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

echo "✅ Setup complete!"
echo "📁 Deployment YAML created at: /opt/course/17/test-init-container.yaml"
echo "🎯 Your task: Add an InitContainer to prepare content in the shared volume"

#!/bin/bash

# Wait for Kubernetes to be ready
echo "Setting up environment..."
while ! kubectl get nodes | grep -q "Ready"; do
  sleep 2
done

# Create the banking namespace
kubectl create namespace banking

# Create the db-client deployment with hardcoded credentials
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-client
  namespace: banking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db-client
  template:
    metadata:
      labels:
        app: db-client
    spec:
      containers:
      - name: db-client
        image: busybox:latest
        command: ['sleep', '3600']
        env:
        - name: DB_USER
          value: "olduser"
        - name: DB_PASS
          value: "oldpassword"
        - name: DB_HOST
          value: "mysql-service"
EOF

echo "Environment ready!"

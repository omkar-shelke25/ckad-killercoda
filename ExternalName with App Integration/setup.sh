#!/bin/bash

# Create the store namespace
kubectl create namespace store

# Create the frontend pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
  namespace: store
spec:
  containers:
  - name: frontend
    image: nginx:alpine
    env:
    - name: BACKEND_URL
      value: "http://backend-service.store.svc.cluster.local"
EOF

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/frontend-pod -n store --timeout=60s

echo "Setup complete! Frontend pod is ready in the store namespace."

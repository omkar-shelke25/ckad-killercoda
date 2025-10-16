#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="manga"
NARUTO_DEP="naruto"
DEMON_DEP="demon-slayer"
NARUTO_IMAGE="public.ecr.aws/nginx/nginx:alpine"
DEMON_IMAGE="public.ecr.aws/docker/library/httpd:alpine"

# Create namespace if it doesn't exist
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Create the naruto Deployment WITHOUT resource requests/limits
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $NARUTO_DEP
  namespace: $NS
  labels:
    app: naruto
    anime: shonen-jump
spec:
  replicas: 2
  selector:
    matchLabels:
      app: naruto
  template:
    metadata:
      labels:
        app: naruto
    spec:
      containers:
        - name: naruto-container
          image: $NARUTO_IMAGE
          ports:
            - containerPort: 80
              name: http
EOF

# Create the demon-slayer Deployment WITHOUT resource requests/limits
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEMON_DEP
  namespace: $NS
  labels:
    app: demon-slayer
    anime: shonen-jump
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demon-slayer
  template:
    metadata:
      labels:
        app: demon-slayer
    spec:
      containers:
        - name: demon-slayer-container
          image: $DEMON_IMAGE
          ports:
            - containerPort: 80
              name: http
EOF

# Wait for deployments to be ready
kubectl -n "$NS" rollout status deploy/"$NARUTO_DEP" --timeout=120s || true
kubectl -n "$NS" rollout status deploy/"$DEMON_DEP" --timeout=120s || true

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo "Namespace: $NS"
echo ""
echo "Deployments created WITHOUT resource requests/limits:"
echo "  1. $NARUTO_DEP (2 replicas) - nginx"
echo "  2. $DEMON_DEP (2 replicas) - httpd"
echo ""
echo "Check current deployments:"
echo "  kubectl get deployments -n $NS"
echo "  kubectl describe deployment $NARUTO_DEP -n $NS"
echo "  kubectl describe deployment $DEMON_DEP -n $NS"
echo ""
echo "Your task: Configure resource requests and limits!"
echo "=========================================="

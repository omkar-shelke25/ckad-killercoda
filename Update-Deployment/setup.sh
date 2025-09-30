#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="prod"
DEP="gamma-app"
INITIAL_IMAGE="nginx:latest"
INITIAL_CONTAINER_NAME="nginx"
INITIAL_REPLICAS=3

# Create namespace if it doesn't exist
kubectl create namespace "$NS" 2>/dev/null || true

# Create the initial Deployment with nginx:latest
if ! kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1; then
  kubectl -n "$NS" create deployment "$DEP" --image="$INITIAL_IMAGE" --replicas="$INITIAL_REPLICAS"
  kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true
else
  # Ensure expected starting shape
  kubectl -n "$NS" set image deploy/"$DEP" "$INITIAL_CONTAINER_NAME"="$INITIAL_IMAGE" || true
  kubectl -n "$NS" scale deploy/"$DEP" --replicas="$INITIAL_REPLICAS" || true
fi

# Wait for deployment to be ready
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true

# Store the original UID for verification later
ORIGINAL_UID=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.metadata.uid}')
echo "$ORIGINAL_UID" > /tmp/original_deployment_uid.txt

echo "Setup complete."
echo "Deployment '$DEP' is created in namespace '$NS' with image=$INITIAL_IMAGE, container name=$INITIAL_CONTAINER_NAME, replicas=$INITIAL_REPLICAS."
echo "Deployment UID: $ORIGINAL_UID"

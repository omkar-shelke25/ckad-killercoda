#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="default"
DEP="api-server"
GOOD_TAG="nginx:1.25.3"   # known-good baseline
START_REPLICAS=3

# Create the initial Deployment if missing
if ! kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1; then
  kubectl -n "$NS" create deployment "$DEP" --image="$GOOD_TAG"
  kubectl -n "$NS" scale deployment "$DEP" --replicas="$START_REPLICAS"
  kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true
else
  # Ensure desired replicas (don't touch image to avoid side effects)
  kubectl -n "$NS" scale deployment "$DEP" --replicas="$START_REPLICAS"
fi

# Pause the rollout so learners start from a paused state (idempotent)
kubectl -n "$NS" rollout pause deploy/"$DEP" || true

echo "Setup complete."
echo "Deployment '$DEP' is created in '$NS' with image=$GOOD_TAG, replicas=$START_REPLICAS, and rollout PAUSED."

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
  # Wait until initial rollout settles (not strictly required)
  kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true
fi

# Ensure it uses the expected image/replicas (idempotent)
kubectl -n "$NS" set image deploy/"$DEP" '*='"$GOOD_TAG" --record=true
kubectl -n "$NS" scale deploy/"$DEP" --replicas="$START_REPLICAS"

# PAUSE the rollout so learners start from a paused state
kubectl -n "$NS" rollout pause deploy/"$DEP"

echo "Setup complete."
echo "Deployment '$DEP' is created in '$NS' with image=$GOOD_TAG, replicas=$START_REPLICAS, and rollout **PAUSED**."

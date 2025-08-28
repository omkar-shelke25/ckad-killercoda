#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="default"
DEP="api-server"
BASE_IMAGE="nginx:1.25.3"   # initial (v1)
BASE_REPLICAS=3

# Create the initial Deployment if missing
if ! kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1; then
  kubectl -n "$NS" create deployment "$DEP" --image="$BASE_IMAGE"
  kubectl -n "$NS" scale deployment "$DEP" --replicas="$BASE_REPLICAS"
  kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true
else
  # Ensure expected starting shape
  kubectl -n "$NS" set image deploy/"$DEP" "$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].name}')"="$BASE_IMAGE" || true
  kubectl -n "$NS" scale deploy/"$DEP" --replicas="$BASE_REPLICAS"
fi

# Pause the rollout so learners start from a paused state (idempotent)
kubectl -n "$NS" rollout pause deploy/"$DEP" || true

echo "Setup complete."
echo "Deployment '$DEP' is created in '$NS' with image=$BASE_IMAGE, replicas=$BASE_REPLICAS, and rollout PAUSED."

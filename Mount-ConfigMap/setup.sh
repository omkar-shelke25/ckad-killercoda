#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="apps"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

echo "Setup complete! Namespace '$NS' is ready."

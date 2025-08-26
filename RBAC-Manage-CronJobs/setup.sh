#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="batch-processing"

# Create only the target namespace so you can do all RBAC work yourself
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

echo "Setup complete! Namespace '$NS' is ready. Create the RBAC objects now."

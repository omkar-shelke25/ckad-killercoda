#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="finance"

# Pre-create only the namespace (as stated in the requirements)
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

echo "Setup complete! Namespace '$NS' is ready. Create the Secret, SA, Role, and RoleBinding now."

#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="neptune"
SA="neptune-sa-v2"
SECRET="neptune-sa-v2-token"

# 1) Ensure namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# 2) Create ServiceAccount if not present
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || kubectl -n "$NS" create sa "$SA"

# 3) Create a Secret of type service-account-token if not already created
if ! kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1; then
  kubectl -n "$NS" create secret generic "$SECRET" --type=kubernetes.io/service-account-token --from-literal=dummy=dummy
fi

# 4) Patch the ServiceAccount to reference this Secret
kubectl -n "$NS" patch sa "$SA" -p "{\"secrets\":[{\"name\":\"$SECRET\"}]}"

echo "Setup complete! ServiceAccount '$SA' with Secret '$SECRET' is ready in namespace '$NS'."

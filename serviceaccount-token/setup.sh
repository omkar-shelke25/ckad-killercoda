#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="neptune"
SA="neptune-sa-v2"
SECRET="neptune-sa-v2-token"

# 1) Ensure namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# 2) Create ServiceAccount if not present
if ! kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1; then
  kubectl -n "$NS" create sa "$SA"
fi

# 3) Create or update a Secret that contains the service account token
# Prefer kubectl create token (requests a token from the API server)
if kubectl create token --help >/dev/null 2>&1; then
  echo "Generating token with 'kubectl create token'..."
  TOKEN=$(kubectl -n "$NS" create token "$SA")
  if [[ -z "$TOKEN" ]]; then
    echo "Failed to obtain token via 'kubectl create token'." >&2
    exit 1
  fi

  # Create or replace the secret containing the token in .data.token
  kubectl -n "$NS" delete secret "$SECRET" >/dev/null 2>&1 || true
  kubectl -n "$NS" create secret generic "$SECRET" --from-literal=token="$TOKEN"
  echo "Secret '$SECRET' created with token data in namespace '$NS'."

  # Patch SA to reference this secret (so labs that inspect SA.secrets see it)
  kubectl -n "$NS" patch sa "$SA" -p "{\"secrets\":[{\"name\":\"$SECRET\"}]}" || true

else
  cat >&2 <<'ERR'
kubectl on this host does not support 'kubectl create token'.
Two options:
  * Upgrade kubectl to >=1.24 so 'kubectl create token' is available, OR
  * Manually create a token (TokenRequest) via the API server and embed it into the Secret.
This setup script cannot automatically create a valid token without 'kubectl create token'.
ERR
  exit 2
fi

echo "Setup complete! ServiceAccount '$SA' with Secret '$SECRET' is ready in namespace '$NS'."

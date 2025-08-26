#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="api"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Manager helper: /opt/env.sh – prints selected env vars from a pod
cat >/opt/env.sh <<'EOS'
#!/bin/sh
# Usage: /opt/env.sh [pod-name] [namespace]
POD="${1:-complex-pod}"
NS="${2:-api}"
echo "Checking env in pod='$POD' ns='$NS' ..."
kubectl -n "$NS" exec "$POD" -- sh -c 'echo "TITLE=$TITLE"; echo "ENDPOINT=$ENDPOINT"; echo "API_KEY=$API_KEY"'
EOS
chmod +x /opt/env.sh

echo "Setup complete! Namespace '$NS' ready. Use '/opt/env.sh' to check env variables."

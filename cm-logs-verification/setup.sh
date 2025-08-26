#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="olly"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Install a tiny helper for managers to fetch logs from the olly namespace.
cat >/usr/local/bin/get-logs-olly <<'EOS'
#!/bin/sh
set -e
NS="olly"
POD="${1:-message-pod}"
echo "Streaming logs from pod '$POD' in namespace '$NS' (Ctrl-C to stop)..."
exec kubectl -n "$NS" logs -f "$POD"
EOS
chmod +x /usr/local/bin/get-logs-olly

echo "Setup complete! Namespace '$NS' ready. Use 'get-logs-olly' to tail pod logs."

#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="pluto"
POD_NAME="holy-api"
RAW_DIR="/opt/course/9"
RAW_POD="${RAW_DIR}/holy-api-pod.yaml"

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Ensure directory for raw template exists
mkdir -p "$RAW_DIR"

# Create the raw Pod template file using busybox (as per request)
# The Pod will be named 'holy-api' and simply sleep so it's Running/Ready.
cat >"$RAW_POD" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: holy-api
  labels:
    app: holy-api
spec:
  containers:
  - name: app
    image: public.ecr.aws/docker/library/busybox:stable
    command: ["/bin/sh","-c","sleep 1d"]
EOF

# Create the single Pod from the raw template (if not already there)
if ! kubectl -n "$NS" get pod "$POD_NAME" >/dev/null 2>&1; then
  kubectl -n "$NS" apply -f "$RAW_POD"
  # BusyBox has no readinessProbe; just give it a moment to start
  kubectl -n "$NS" wait --for=condition=Ready pod/"$POD_NAME" --timeout=90s || true
fi

echo "Setup complete!"
echo "Raw Pod template: $RAW_POD"

#!/bin/bash

set -e

# Create the target namespace
kubectl create namespace netpol-demo2 --dry-run=client -o yaml | kubectl apply -f -

# Create the isolated Pod with a clear identifying label
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: isolated
  namespace: netpol-demo2
  labels:
    app: isolated
spec:
  containers:
  - name: alpine
    image: alpine:3.20
    command: ["sleep", "28800"]
EOF

# Wait for readiness (best-effort)
kubectl wait --for=condition=Ready pod/isolated -n netpol-demo2 --timeout=120s || true

echo "Setup complete! Pod 'isolated' is created in the netpol-demo2 namespace."

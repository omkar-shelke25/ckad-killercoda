#!/bin/bash
set -euo pipefail

NS="netpol-demo6"

# Create namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Pre-create pods (as specified)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-a
  namespace: netpol-demo6
  labels:
    app: pod-a
spec:
  containers:
  - name: nginx
    image: nginx:1.25
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
  namespace: netpol-demo6
  labels:
    app: pod-b
spec:
  containers:
  - name: nginx
    image: nginx:1.25
EOF

# Wait until the pods are Ready
kubectl -n "$NS" wait --for=condition=Ready pod/pod-a --timeout=120s
kubectl -n "$NS" wait --for=condition=Ready pod/pod-b --timeout=120s

echo "✅ Environment ready: namespace '$NS' with pods 'pod-a' and 'pod-b' are Running."

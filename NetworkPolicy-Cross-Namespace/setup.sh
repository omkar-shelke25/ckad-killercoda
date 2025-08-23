#!/usr/bin/env bash
set -euo pipefail

# Create namespaces
kubectl create namespace netpol-demo9 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-ns --dry-run=client -o yaml | kubectl apply -f -

# Create source Pod in netpol-demo9
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: source-pod
  namespace: netpol-demo9
  labels:
    app: source
spec:
  containers:
  - name: alpine
    image: alpine:3.20
    command: ["sleep", "3600"]
EOF

# Create target Pod in external-ns
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: target-pod
  namespace: external-ns
  labels:
    app: target
spec:
  containers:
  - name: nginx
    image: nginx:1.25
EOF

# Best-effort readiness waits
kubectl wait --for=condition=Ready pod/source-pod -n netpol-demo9 --timeout=120s || true
kubectl wait --for=condition=Ready pod/target-pod -n external-ns --timeout=120s || true

echo "Environment ready."

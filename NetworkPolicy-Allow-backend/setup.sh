#!/usr/bin/env bash
set -euo pipefail

# Create namespace
kubectl create namespace netpol-demo1 --dry-run=client -o yaml | kubectl apply -f -

# Backend pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: netpol-demo1
  labels:
    app: backend
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
EOF

# Frontend pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: netpol-demo1
  labels:
    role: frontend
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sleep", "28800"]
EOF

# Best-effort readiness waits
kubectl wait --for=condition=Ready pod/backend  -n netpol-demo1 --timeout=120s || true
kubectl wait --for=condition=Ready pod/frontend -n netpol-demo1 --timeout=120s || true

echo "Environment ready."

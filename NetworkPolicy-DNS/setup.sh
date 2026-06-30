#!/bin/bash
set -e

echo "Creating namespace and isolated Pod..."

kubectl create namespace netpol-demo2 --dry-run=client -o yaml | kubectl apply -f -

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

kubectl wait --for=condition=Ready pod/isolated -n netpol-demo2 --timeout=120s || true

echo ""
echo "Setup complete! Pod 'isolated' is running in namespace 'netpol-demo2'."
echo "Your task: create a NetworkPolicy named 'deny-all-except-dns' to lock it down."

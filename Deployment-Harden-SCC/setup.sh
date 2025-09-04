#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."

NS="net-acm"
DEP="busybox"
SVC="busybox-svc"

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Minimal, unsecured deployment to be remediated
if ! kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1; then
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  namespace: net-acm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - name: bb
        image: busybox:1.36.1
        command: ["sh","-c","sleep 3600"]
EOF
fi

# Dummy Service (not essential, created per request)
if ! kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1; then
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: busybox-svc
  namespace: net-acm
spec:
  selector:
    app: busybox
  ports:
  - port: 8080
    targetPort: 8080
EOF
fi

echo "⏳ Waiting for initial Deployment to be ready..."
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true

echo "✅ Environment ready. Update Deployment 'busybox' with the required security settings."

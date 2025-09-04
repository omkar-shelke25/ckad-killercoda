#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."

NS="net-acm"
DEP="busybox"
SVC="busybox-svc"

# Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

# Minimal, unsecured deployment to start with (to be remediated by the learner)
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

# A dummy ClusterIP Service (not functionally used, just pre-created as requested)
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
  - port: 80
    targetPort: 80
EOF
fi

# Ensure directory for the verification script exists
sudo mkdir -p /net-acm
sudo chmod 755 /net-acm

echo "⏳ Waiting for initial Deployment to be ready..."
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true

echo "✅ Environment ready. Remediate Deployment 'busybox' in namespace 'net-acm' and create /net-acm/id.sh."

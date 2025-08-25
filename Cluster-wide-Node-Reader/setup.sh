#!/bin/bash
set -euo pipefail

echo "⏳ Initializing scenario..."

# Pre-create target namespace to focus on RBAC
kubectl get ns monitoring >/dev/null 2>&1 || kubectl create namespace monitoring >/dev/null

# A placeholder Deployment that represents a monitoring UI
# (Initially has NO serviceAccountName — learners must assign it.)
kubectl -n monitoring apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-inspector-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-inspector-ui
  template:
    metadata:
      labels:
        app: node-inspector-ui
    spec:
      containers:
      - name: ui
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Wait for the first ReplicaSet to create at least one Pod
kubectl -n monitoring rollout status deploy/node-inspector-ui --timeout=90s >/dev/null 2>&1 || true

echo "✅ Namespace 'monitoring' and Deployment 'node-inspector-ui' are ready."
echo "👉 Proceed to create SA, ClusterRole, ClusterRoleBinding, and attach SA to the Deployment."

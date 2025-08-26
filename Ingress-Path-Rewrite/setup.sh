#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="legacy"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Ensure legacy app deployment & service exist (httpd image per requirement)
if ! kubectl -n "$NS" get deploy legacy-app >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy
  template:
    metadata:
      labels:
        app: legacy
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: legacy-svc
spec:
  selector:
    app: legacy
  ports:
  - port: 80
    targetPort: 80
EOF
fi

echo "Setup complete! Namespace and backend Service are ready."

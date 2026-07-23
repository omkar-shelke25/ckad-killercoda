#!/bin/bash
set -e

echo "Preparing the lab environment..."

# Create namespace (idempotent)
kubectl create namespace venus --dry-run=client -o yaml | kubectl apply -f -

# Deploy api: lightweight HTTP server on port 2222
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: venus
  labels:
    app: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: python:3.11-alpine
        command: ["/bin/sh", "-c"]
        args:
          - |
            mkdir -p /www && echo "OK" > /www/index.html
            python -m http.server 2222 --directory /www
        ports:
        - containerPort: 2222
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: venus
spec:
  selector:
    app: api
  ports:
  - port: 2222
    targetPort: 2222
EOF

# Deploy frontend: busybox Pod used to test egress connectivity
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: venus
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: busybox:1.36.1
        command: ["sh", "-c", "sleep 7d"]
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: venus
spec:
  selector:
    app: frontend
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Wait for both Deployments to be ready before handing off to the user
kubectl -n venus rollout status deployment/api      --timeout=180s || true
kubectl -n venus rollout status deployment/frontend --timeout=180s || true

echo ""
echo "Lab ready. Namespace 'venus' contains:"
echo "  Deployment 'api'      — HTTP server on port 2222"
echo "  Deployment 'frontend' — busybox, used to test outbound connectivity"
echo "  Service    'api'      — ClusterIP on port 2222"
echo "  Service    'frontend'"

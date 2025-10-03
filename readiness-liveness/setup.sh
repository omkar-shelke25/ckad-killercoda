#!/bin/bash
set -euo pipefail

echo "🚀 Setting up the galaxy namespace and warp-core deployment..."

# Create galaxy namespace
kubectl create namespace galaxy

# Create ConfigMap with health check pages
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: warp-core-pages
  namespace: galaxy
data:
  helathz: "OK"
  readyz: "READY"
EOF

# Create initial Deployment without probes
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: warp-core
  namespace: galaxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: warp-core
  template:
    metadata:
      labels:
        app: warp-core
    spec:
      containers:
      - name: httpd
        image: public.ecr.aws/docker/library/httpd:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: health-pages
          mountPath: /usr/local/apache2/htdocs
      volumes:
      - name: health-pages
        configMap:
          name: warp-core-pages
EOF

# Wait for deployment to be ready
echo "⏳ Waiting for initial deployment to be ready..."
kubectl -n galaxy wait --for=condition=available --timeout=90s deployment/warp-core

echo "✅ Galaxy namespace and warp-core deployment are ready!"
echo "📝 Your mission: Add readiness and liveness probes to the warp-core deployment."

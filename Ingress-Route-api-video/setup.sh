#!/bin/bash
set -euo pipefail

echo "Preparing lab environment for Ingress task..."

NS="streaming"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Ensure API deployment and service exist
if ! kubectl -n "$NS" get deploy api-server >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
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
        image: hashicorp/http-echo:0.2.3
        args: ["-text=hello-from-api"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 5678
EOF
fi

# Ensure VIDEO deployment and service exist
if ! kubectl -n "$NS" get deploy video-processor >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: video-processor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: video
  template:
    metadata:
      labels:
        app: video
    spec:
      containers:
      - name: video
        image: hashicorp/http-echo:0.2.3
        args: ["-text=hello-from-video"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: video-service
spec:
  selector:
    app: video
  ports:
  - port: 80
    targetPort: 5678
EOF
fi

echo "Setup complete! Namespace and backend services are ready."

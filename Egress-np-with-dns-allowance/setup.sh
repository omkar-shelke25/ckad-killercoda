#!/bin/bash
set -euo pipefail

echo "Preparing lab..."

NS="venus"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# --- API deployment (serves HTTP on 2222) ---
if ! kubectl -n "$NS" get deploy api >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
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
      - name: web
        image: python:3.11-alpine
        command: ["/bin/sh","-c"]
        args:
          - |
            mkdir -p /www
            echo "OK" > /www/index.html
            python -m http.server 2222 --directory /www
        ports:
        - containerPort: 2222
                       
---
apiVersion: v1
kind: Service
metadata:
  name: api
  labels:
    app: api
spec:
  selector:
    app: api
  ports:
  - name: http
    port: 2222
    targetPort: 2222
EOF
fi

# --- Frontend deployment (provides a place to test egress) ---
if ! kubectl -n "$NS" get deploy frontend >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
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
      - name: bb
        image: busybox:1.36.1
        command: ["sh","-c","sleep 7d"]
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  selector:
    app: frontend
  ports:
  - name: http
    port: 8080
    targetPort: 80
EOF
fi

kubectl -n "$NS" rollout status deploy/api --timeout=180s || true
kubectl -n "$NS" rollout status deploy/frontend --timeout=180s || true

echo "Setup complete. Namespace '$NS' has Deployments 'api' and 'frontend' and Services 'api' and 'frontend'."

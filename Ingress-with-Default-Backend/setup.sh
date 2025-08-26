#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="main"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Precreate backends if missing (using nginx for realism, as requested)
if ! kubectl -n "$NS" get deploy main-site >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: main-site
  template:
    metadata:
      labels:
        app: main-site
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: main-site-svc
spec:
  selector:
    app: main-site
  ports:
  - port: 80
    targetPort: 80
EOF
fi

if ! kubectl -n "$NS" get deploy error-page-app >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: error-page-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: error-page
  template:
    metadata:
      labels:
        app: error-page
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: error-page-svc
spec:
  selector:
    app: error-page
  ports:
  - port: 80
    targetPort: 80
EOF
fi

echo "Setup complete! Namespace and backend Services are ready."

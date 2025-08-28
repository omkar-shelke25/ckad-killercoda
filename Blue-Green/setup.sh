#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="ios"
DEP_BLUE="web-app-blue"
SVC="web-app-service"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Create BLUE deployment (nginx:1.19, 3 replicas) with labels app=web-app, color=blue
if ! kubectl -n "$NS" get deploy "$DEP_BLUE" >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-blue
  labels:
    app: web-app
    color: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      color: blue
  template:
    metadata:
      labels:
        app: web-app
        color: blue
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
EOF
fi

# Service selects app=web-app AND color=blue (so only blue receives traffic initially)
if ! kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1; then
cat <<'EOF' | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  labels:
    app: web-app
spec:
  selector:
    app: web-app
    color: blue
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF
fi

kubectl -n "$NS" rollout status deploy/"$DEP_BLUE" --timeout=180s >/dev/null 2>&1 || true
echo "Setup complete: namespace 'ios', BLUE deployment and Service ready."

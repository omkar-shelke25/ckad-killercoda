#!/bin/bash
set -euo pipefail

echo "🚀 Preparing jupiter namespace with deployments..."

NS="jupiter"
kubectl get ns $NS >/dev/null 2>&1 || kubectl create ns $NS

# Create app1 deployment and service
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: $NS
  labels:
    app: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Service
metadata:
  name: app1
  namespace: $NS
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: $NS
  labels:
    app: app2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Service
metadata:
  name: app2
  namespace: $NS
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: $NS
  labels:
    app: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $NS
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-pod
  namespace: $NS
  labels:
    app: test-pod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-pod
  template:
    metadata:
      labels:
        app: test-pod
    spec:
      containers:
      - name: test-pod
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
EOF

# Wait for pods to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl -n $NS rollout status deployment/app1 --timeout=60s
kubectl -n $NS rollout status deployment/app2 --timeout=60s
kubectl -n $NS rollout status deployment/redis --timeout=60s
kubectl -n $NS rollout status deployment/test-pod --timeout=60s

echo "✅ Environment ready. Create a NetworkPolicy named 'np-redis' to restrict Redis access."
echo ""
echo "📋 Current deployments in namespace $NS:"
kubectl -n $NS get deployments
echo ""
echo "📋 Current services in namespace $NS:"
kubectl -n $NS get services

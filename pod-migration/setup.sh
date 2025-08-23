#!/usr/bin/env bash
set -euo pipefail

# CKAD scenario: prime has 6 pods; the 4th pod uses container name `mars-container`.
# Goal (for examinees later): migrate only that pod to `mars` namespace.

echo "==> Creating namespaces: prime, mars"
kubectl get ns prime >/dev/null 2>&1 || kubectl create ns prime
kubectl get ns mars  >/dev/null 2>&1 || kubectl create ns mars

echo "==> Creating 6 pods in namespace 'prime' with unique labels and container names"
cat <<'YAML' | kubectl apply -f -
---
apiVersion: v1
kind: Pod
metadata:
  name: web-app-01
  namespace: prime
  labels:
    app: web-app
    id: web-app-01
spec:
  containers:
  - name: prime-01
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: web-app-02
  namespace: prime
  labels:
    app: web-app
    id: web-app-02
spec:
  containers:
  - name: prime-02
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: web-app-03
  namespace: prime
  labels:
    app: web-app
    id: web-app-03
spec:
  containers:
  - name: prime-03
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
# This is the odd one: container name is mars-container (doesn't belong to 'prime')
apiVersion: v1
kind: Pod
metadata:
  name: web-app-04
  namespace: prime
  labels:
    app: web-app
    id: web-app-04
spec:
  containers:
  - name: mars-container
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: web-app-05
  namespace: prime
  labels:
    app: web-app
    id: web-app-05
spec:
  containers:
  - name: prime-05
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: web-app-06
  namespace: prime
  labels:
    app: web-app
    id: web-app-06
spec:
  containers:
  - name: prime-06
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
YAML

echo "==> Waiting for pods to be Running in 'prime'"
kubectl wait --for=condition=Ready pod/web-app-01 -n prime --timeout=120s
kubectl wait --for=condition=Ready pod/web-app-02 -n prime --timeout=120s
kubectl wait --for=condition=Ready pod/web-app-03 -n prime --timeout=120s
kubectl wait --for=condition=Ready pod/web-app-04 -n prime --timeout=120s
kubectl wait --for=condition=Ready pod/web-app-05 -n prime --timeout=120s
kubectl wait --for=condition=Ready pod/web-app-06 -n prime --timeout=120s

echo "✅ Environment ready."

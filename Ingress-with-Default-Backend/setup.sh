#!/bin/bash

echo "Preparing the lab environment..."

# ── 1. Install nginx Ingress Controller (baremetal / NodePort) ────────────────
echo "Installing nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml >/dev/null 2>&1

echo "Waiting for Ingress Controller to be ready (up to 3 minutes)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s >/dev/null 2>&1 \
  || echo "Warning: controller not ready within timeout — continuing anyway"

sleep 5

# ── 2. Create namespace (idempotent) ─────────────────────────────────────────
kubectl create namespace main --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1

# ── 3. Deploy main-site backend ───────────────────────────────────────────────
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-site
  namespace: main
  labels:
    app: main-site
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
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo 'main-site: Welcome to the Main Site' > /usr/share/nginx/html/index.html
            exec nginx -g 'daemon off;'
        ports:
        - containerPort: 80
EOF

kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: main-site-svc
  namespace: main
spec:
  selector:
    app: main-site
  ports:
  - port: 80
    targetPort: 80
EOF

# ── 4. Deploy error-page backend ──────────────────────────────────────────────
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: error-page-app
  namespace: main
  labels:
    app: error-page
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
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args:
          - |
            echo 'error-page: Custom 404 Page Not Found' > /usr/share/nginx/html/index.html
            exec nginx -g 'daemon off;'
        ports:
        - containerPort: 80
EOF

kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: error-page-svc
  namespace: main
spec:
  selector:
    app: error-page
  ports:
  - port: 80
    targetPort: 80
EOF

# ── 5. Wait for backend pods ──────────────────────────────────────────────────
kubectl -n main rollout status deployment/main-site      --timeout=120s 2>/dev/null || true
kubectl -n main rollout status deployment/error-page-app --timeout=120s 2>/dev/null || true

# ── 6. Detect NodePort and configure /etc/hosts ───────────────────────────────
NODE_IP=$(kubectl get nodes \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

grep -qF "main.example.com" /etc/hosts \
  || echo "$NODE_IP  main.example.com" >> /etc/hosts

echo "$HTTP_PORT" > /tmp/ingress_http_port.txt

echo ""
echo "Lab ready. Namespace 'main' contains:"
echo "  Deployment 'main-site'      -> Service 'main-site-svc'  (port 80)"
echo "  Deployment 'error-page-app' -> Service 'error-page-svc' (port 80)"
echo ""
echo "Nginx Ingress Controller NodePort (HTTP): $HTTP_PORT"
echo "  main.example.com -> $NODE_IP  (added to /etc/hosts)"
echo ""
echo "After creating the Ingress, test with:"
echo "  curl http://main.example.com:$HTTP_PORT/"
echo "  curl -H 'Host: other.example.com' http://main.example.com:$HTTP_PORT/"

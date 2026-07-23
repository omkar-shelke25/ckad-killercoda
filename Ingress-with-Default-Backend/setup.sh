#!/bin/bash
set -e

echo "Preparing the lab environment..."

# ── 1. Install nginx Ingress Controller (baremetal manifest) ──────────────────
echo "Installing nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml >/dev/null 2>&1

# ── 2. Patch the controller Deployment to use hostNetwork ─────────────────────
# hostNetwork: true makes the controller bind directly to ports 80 and 443 on
# the host node — no NodePort suffix is needed when testing with curl.
# dnsPolicy must be set to ClusterFirstWithHostNet so cluster DNS still works.
echo "Configuring Ingress Controller to bind on host ports 80 and 443..."
kubectl -n ingress-nginx patch deployment ingress-nginx-controller \
  --type=json \
  -p='[
    {"op":"add","path":"/spec/template/spec/hostNetwork","value":true},
    {"op":"add","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirstWithHostNet"}
  ]' >/dev/null 2>&1

echo "Waiting for Ingress Controller to be ready (up to 3 minutes)..."
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller \
  --timeout=180s \
  || echo "Warning: rollout timeout — continuing anyway"

sleep 5

# ── 3. Create namespace (idempotent) ─────────────────────────────────────────
kubectl create namespace main --dry-run=client -o yaml | kubectl apply -f -

# ── 4. Deploy main-site backend ───────────────────────────────────────────────
# Serves a response containing "main-site" so verification can confirm routing.
kubectl apply -f - <<'EOF'
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

kubectl apply -f - <<'EOF'
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

# ── 5. Deploy error-page backend ──────────────────────────────────────────────
# Serves a response containing "error-page" so verification can confirm routing.
kubectl apply -f - <<'EOF'
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

kubectl apply -f - <<'EOF'
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

# ── 6. Wait for backend pods ──────────────────────────────────────────────────
kubectl -n main rollout status deployment/main-site      --timeout=120s || true
kubectl -n main rollout status deployment/error-page-app --timeout=120s || true

# ── 7. Configure /etc/hosts using the node where the controller is running ────
# Because the controller uses hostNetwork, port 80 is bound on that node's IP.
CTRL_IP=$(kubectl -n ingress-nginx get pod \
  -l app.kubernetes.io/component=controller \
  -o jsonpath='{.items[0].status.hostIP}' 2>/dev/null \
  || kubectl get nodes \
       -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

grep -qF "main.example.com" /etc/hosts \
  || echo "$CTRL_IP  main.example.com" >> /etc/hosts

echo ""
echo "Lab ready. Namespace 'main' contains:"
echo "  Deployment 'main-site'      -> Service 'main-site-svc'  (port 80)"
echo "  Deployment 'error-page-app' -> Service 'error-page-svc' (port 80)"
echo ""
echo "Nginx Ingress Controller: bound to $CTRL_IP on port 80 (HTTP) and 443 (HTTPS)"
echo "  main.example.com -> $CTRL_IP  (added to /etc/hosts)"
echo ""
echo "After creating the Ingress, test with:"
echo "  curl http://main.example.com/"
echo "  curl -H 'Host: other.example.com' http://main.example.com/"

#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Preparing lab environment for Ingress task (Helm-only Traefik)..."

# --- CONFIGURATION ---
NS="streaming"
TRAEFIK_NS="traefik"
TEST_HOST="streams.local"
HTTP_NODEPORT=30099
HTTPS_NODEPORT=30443
# ---------------------

# Create namespaces if not exist
kubectl get ns "${NS}" >/dev/null 2>&1 || kubectl create namespace "${NS}"
kubectl get ns "${TRAEFIK_NS}" >/dev/null 2>&1 || kubectl create namespace "${TRAEFIK_NS}"
echo "✅ Namespaces created or already exist."

# === BACKEND SERVICES ===
echo "📦 Deploying API and VIDEO backends in namespace '${NS}'..."

# API backend
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

# VIDEO backend
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

echo "✅ Backend services deployed."

# === TRAEFIK INSTALL VIA HELM ONLY ===
echo "⚙️ Installing/upgrading Traefik via Helm (NodePort mode)..."
helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

# Uninstall first to ensure clean state
helm uninstall traefik -n "${TRAEFIK_NS}" 2>/dev/null || true
sleep 2

# Install with correct NodePort settings
helm install traefik traefik/traefik \
  --namespace "${TRAEFIK_NS}" \
  --set ports.web.nodePort=${HTTP_NODEPORT} \
  --set ports.websecure.nodePort=${HTTPS_NODEPORT} \
  --set service.type=NodePort

echo "✅ Traefik installed via Helm and exposed via NodePort ${HTTP_NODEPORT}/${HTTPS_NODEPORT}."

# Verify the service
echo "🔍 Verifying Traefik service..."
kubectl -n "${TRAEFIK_NS}" get svc traefik

echo ""
echo "📝 Summary:"
echo "  - HTTP available at: NodePort ${HTTP_NODEPORT}"
echo "  - HTTPS available at: NodePort ${HTTPS_NODEPORT}"
echo "  - Access via: curl http://<node-ip>:${HTTP_NODEPORT}"

#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Preparing lab environment for Ingress task (Helm-only Traefik)..."

# --- CONFIGURATION ---
NS="streaming"
TRAEFIK_NS="traefik"
HTTP_NODEPORT=30099
HTTPS_NODEPORT=30443
TEST_HOST="streams.local"
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

helm upgrade --install traefik traefik/traefik \
  --namespace "${TRAEFIK_NS}" \
  --set service.type=NodePort \
  --set service.nodePorts.http=${HTTP_NODEPORT} \
  --set service.nodePorts.https=${HTTPS_NODEPORT} \
  --set service.externalTrafficPolicy=Cluster

echo "✅ Traefik installed/upgraded via Helm and exposed via NodePort ${HTTP_NODEPORT}/${HTTPS_NODEPORT}."

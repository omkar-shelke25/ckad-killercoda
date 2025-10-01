#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="exam-app"
INGRESS_NAME="api-ingress"
SERVICE_NAME="external-api"

# Create namespace
kubectl create namespace "$NS" 2>/dev/null || true

# Install NGINX Ingress Controller if not already installed
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml >/dev/null 2>&1 || true

# Wait for ingress controller to be ready
echo "Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s 2>/dev/null || true

# Give it a few more seconds to fully initialize
sleep 10

# Create the Ingress resource that routes to external-api service
cat <<EOF | kubectl apply -f - >/dev/null 2>&1
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $INGRESS_NAME
  namespace: $NS
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: $SERVICE_NAME
            port:
              number: 80
EOF

# Wait a moment for Ingress to be created
sleep 5

# Get the Ingress controller NodePort for HTTP
INGRESS_HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Store the access URL for later use
echo "http://localhost:${INGRESS_HTTP_PORT}/api/" > /tmp/ingress_url.txt

echo ""
echo "Setup complete."
echo "==========================================="
echo "Namespace: $NS"
echo "Ingress: $INGRESS_NAME"
echo "Expected Service: $SERVICE_NAME (NOT YET CREATED - this is your task!)"
echo ""
echo "Ingress Access URL: http://localhost:${INGRESS_HTTP_PORT}/api/"
echo "==========================================="
echo ""
echo "The Ingress is configured but will return 503 errors"
echo "because the Service '$SERVICE_NAME' does not exist yet."

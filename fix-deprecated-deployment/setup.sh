#!/bin/bash
set -euo pipefail

NAMESPACE="migration"
MANIFEST_DIR="/opt/course/api-fix"
DEPLOYMENT_YAML="$MANIFEST_DIR/legacy-app.yaml"
SERVICE_YAML="$MANIFEST_DIR/legacy-app-service.yaml"

# Ensure directory
mkdir -p "$MANIFEST_DIR"

# Create namespace if missing (idempotent)
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  kubectl create namespace "$NAMESPACE"
  echo "✅ Namespace created: $NAMESPACE"
else
  echo "ℹ️ Namespace already exists: $NAMESPACE"
fi

# Write a current apps/v1 Deployment (replace image/values as needed)
cat > "$DEPLOYMENT_YAML" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: migration
  labels:
    app: legacy-app
    version: v1.0.0
    environment: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: legacy-app
  template:
    metadata:
      labels:
        app: legacy-app
        version: v1.0.0
    spec:
      containers:
      - name: web
        image: nginx:1.20
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        env:
        - name: APP_VERSION
          value: "1.0.0"
        - name: ENVIRONMENT
          value: "production"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
EOF

# Service YAML
cat > "$SERVICE_YAML" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: legacy-app-service
  namespace: migration
  labels:
    app: legacy-app
spec:
  selector:
    app: legacy-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
EOF

# Apply both resources

kubectl apply -f "$SERVICE_YAML"



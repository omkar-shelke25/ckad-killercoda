#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

# Create the directory structure
mkdir -p /ancient-tiger

# Create the anaconda namespace using kubectl
kubectl create namespace anaconda

kubectl create namespace viper

# Create the deprecated manifest file. This is written the way a real
# manifest from an older Kubernetes release would look — apps/v1beta1 was
# removed in v1.16, and its DeploymentSpec also had fields (like rollbackTo)
# that no longer exist in apps/v1. kubectl-convert handles both automatically;
# hand-editing only the apiVersion line and leaving rollbackTo behind will
# cause `kubectl apply` to reject the manifest once it's apps/v1.
cat > /ancient-tiger/app.yaml << 'EOF'
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: web-app
  namespace: anaconda
spec:
  replicas: 3
  rollbackTo:
    revision: 0
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: public.ecr.aws/nginx/nginx:latest
        ports:
        - containerPort: 80
EOF

echo ""
echo "Setup complete."
echo "---------------------------------------------"
echo "The 'anaconda' and 'viper' namespaces have been created"
echo "A deprecated manifest is located at: /ancient-tiger/app.yaml"
echo "It uses apps/v1beta1 — removed in Kubernetes v1.16 — and a"
echo "field (rollbackTo) that no longer exists in apps/v1"
echo "---------------------------------------------"

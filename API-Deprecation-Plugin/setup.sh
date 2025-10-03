#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

# Create the directory structure
mkdir -p /ancient-tiger

# Create the anaconda namespace using kubectl
kubectl create namespace anaconda

kubectl create namespace viper

# Create the deprecated manifest file (based on v1.28 with deprecated APIs)
cat > /ancient-tiger/app.yaml << 'EOF'
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: web-app
  namespace: anaconda
spec:
  replicas: 3
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
echo "The 'anaconda' namespace has been created"
echo "A deprecated manifest is located at: /ancient-tiger/app.yaml"
echo "The manifest uses deprecated API versions from Kubernetes v1.28"
echo "---------------------------------------------"

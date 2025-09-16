#!/bin/bash
set -euo pipefail

echo "🚀 Setting up e-commerce platform environment..."

NAMESPACE="ecommerce-platform"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "📦 Deploying initial web frontend..."

# Create initial deployment with minimal configuration
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-frontend-deployment
  namespace: $NAMESPACE
  labels:
    app: ecommerce-frontend
    tier: frontend
    version: v2.1.0
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce-frontend
  template:
    metadata:
      labels:
        app: ecommerce-frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: SERVICE_NAME
          value: "ecommerce-frontend"
        command: 
        - /bin/sh
        - -c
        - |
          echo '<!DOCTYPE html>
          <html>
          <head>
              <title>E-Commerce Platform</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
                  .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                  .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
                  .status { background: #2ecc71; color: white; padding: 10px; border-radius: 4px; margin: 15px 0; }
                  .info { background: #ecf0f1; padding: 15px; border-radius: 4px; margin: 10px 0; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1 class="header">🛍️ E-Commerce Frontend</h1>
                  <div class="status">✅ Service Status: Online</div>
                  <div class="info">
                      <strong>Pod:</strong> '$(hostname)'<br>
                      <strong>Environment:</strong> Production<br>
                      <strong>Version:</strong> v2.1.0<br>
                      <strong>Ready for:</strong> Product Launch Campaign
                  </div>
                  <p>This frontend is ready to handle high traffic loads!</p>
              </div>
          </body>
          </html>' > /usr/share/nginx/html/index.html &&
          nginx -g 'daemon off;'
EOF

# Wait for deployment to be ready
echo "⏳ Waiting for initial deployment..."
kubectl -n $NAMESPACE rollout status deployment/ecommerce-frontend-deployment --timeout=60s

echo "✅ Environment setup complete!"
echo ""
echo "📊 Current deployment status:"
kubectl -n $NAMESPACE get deployment ecommerce-frontend-deployment
echo ""
echo "🔍 Current pods:"
kubectl -n $NAMESPACE get pods -l app=ecommerce-frontend --show-labels
echo ""
echo "⚠️  Current Issues:"
echo "   • Only 2 replicas (insufficient for traffic surge)"
echo "   • Missing 'role: webfrontend' label for service discovery"
echo "   • No external service exposure configured"
echo ""
echo "🎯 Your Mission:"
echo "   1. Scale deployment to 5 replicas"
echo "   2. Add 'role: webfrontend' label to pod template"
echo "   3. Create NodePort service for external access"

#!/bin/bash
set -euo pipefail

echo "🚀 Setting up multi-tenant production environment..."

NAMESPACE="team-alpha-production"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "📊 Configuring resource quota for Team Alpha..."

# Create resource quota for the namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-alpha-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
    persistentvolumeclaims: "5"
    services: "3"
EOF

echo "🚀 Deploying backend API service without resource requests..."

# Create deployment without resource requests
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api-service
  namespace: $NAMESPACE
  labels:
    app: backend-api
    tier: backend
    team: alpha
    version: v1.3.2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
        tier: backend
        team: alpha
    spec:
      containers:
      - name: api-server
        image: nginx:1.21-alpine
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: TEAM
          value: "alpha"
        - name: API_VERSION
          value: "v1.3.2"
        command:
        - /bin/sh
        - -c
        - |
          echo '<!DOCTYPE html>
          <html>
          <head>
              <title>Backend API Service - Team Alpha</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; background: #2c3e50; color: white; }
                  .container { background: #34495e; padding: 20px; border-radius: 8px; }
                  .header { color: #3498db; border-bottom: 2px solid #e74c3c; padding-bottom: 10px; }
                  .status { background: #27ae60; color: white; padding: 10px; border-radius: 4px; margin: 15px 0; }
                  .warning { background: #f39c12; color: white; padding: 10px; border-radius: 4px; margin: 15px 0; }
                  .info { background: #34495e; padding: 15px; border: 1px solid #7f8c8d; border-radius: 4px; margin: 10px 0; }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1 class="header">🚀 Backend API Service</h1>
                  <div class="status">✅ Service Status: Running</div>
                  <div class="warning">⚠️ Resource Requests: Not Configured</div>
                  <div class="info">
                      <strong>Pod:</strong> '$(hostname)'<br>
                      <strong>Team:</strong> Alpha<br>
                      <strong>Environment:</strong> Production<br>
                      <strong>Version:</strong> v1.3.2<br>
                      <strong>Namespace:</strong> team-alpha-production
                  </div>
                  <p><strong>Action Required:</strong> Configure memory requests to 50% of namespace quota!</p>
              </div>
          </body>
          </html>' > /usr/share/nginx/html/index.html &&
          nginx -g 'daemon off;'
EOF

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl -n $NAMESPACE rollout status deployment/backend-api-service --timeout=60s

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "📊 Current Resource Quota Status:"
kubectl -n $NAMESPACE describe resourcequota team-alpha-quota
echo ""
echo "🚀 Current Deployment Status:"
kubectl -n $NAMESPACE get deployment backend-api-service
echo ""
echo "🔍 Current Pod Resource Configuration:"
kubectl -n $NAMESPACE describe deployment backend-api-service | grep -A 10 "Containers:" | grep -E "(Requests|Limits):" || echo "   ⚠️  No resource requests configured"
echo ""
echo "🎯 Your Mission:"
echo "   1. Analyze the namespace resource quota"
echo "   2. Calculate 50% of maximum memory allocation"
echo "   3. Configure deployment with appropriate memory requests"
echo "   4. Ensure compliance with resource governance policies"
echo ""
echo "💡 Hint: Check 'kubectl describe resourcequota' to see memory limits!"

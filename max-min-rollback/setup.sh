#!/bin/bash
set -euo pipefail

echo "🚀 Setting up production web platform environment..."

NAMESPACE="prod"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "📦 Deploying production web frontend (current version)..."

# Create initial deployment with default rolling update strategy
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web1
  namespace: $NAMESPACE
  labels:
    app: web-frontend
    tier: frontend
    environment: production
spec:
  replicas: 10
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
        tier: frontend
        version: perl
    spec:
      containers:
      - name: nginx
        image: public.ecr.aws/nginx/nginx:perl
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

# Create service for the deployment
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web1-service
  namespace: $NAMESPACE
  labels:
    app: web-frontend
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: web-frontend
EOF

# Wait for deployment to be ready
echo "⏳ Waiting for production deployment to stabilize..."
kubectl -n $NAMESPACE rollout status deployment/web1 --timeout=120s

echo "✅ Environment setup complete!"
echo ""
echo "📊 Current Production Status:"
kubectl -n $NAMESPACE get deployment web1
echo ""
echo "🔍 Pod Distribution:"
kubectl -n $NAMESPACE get pods -l app=web-frontend --show-labels
echo ""
echo "📋 Current Image Version:"
kubectl -n $NAMESPACE get deployment web1 -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo ""
echo "⚠️  Current Configuration Issues:"
echo "   • Default rolling update strategy (25% maxUnavailable, 25% maxSurge)"
echo "   • Not suitable for zero-downtime requirement"
echo "   • Image version: perl (old version)"
echo ""
echo "🎯 Your Mission:"
echo "   1. Update image to: public.ecr.aws/nginx/nginx:stable-perl"
echo "   2. Configure rolling update: maxUnavailable=0%, maxSurge=5%"
echo "   3. Monitor rollout to completion"
echo "   4. Simulate failure and perform rollback"
echo "   5. Verify rollback success"
echo ""
echo "💡 Tip: Use 'kubectl rollout' commands to manage the update process"

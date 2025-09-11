#!/bin/bash
set -e

# Set context to cluster1
kubectl config use-context cluster1

# Create the migration namespace
kubectl create namespace migration

# Create the course directory
mkdir -p /opt/course/api-fix

# Create a deployment with deprecated API version (extensions/v1beta1)
cat > /opt/course/api-fix/legacy-app.yaml << 'EOF'
apiVersion: extensions/v1beta1
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
      restartPolicy: Always
EOF

# Try to apply the deprecated deployment (this might generate warnings)
kubectl apply -f /opt/course/api-fix/legacy-app.yaml

# Create a service for the app
cat > /opt/course/api-fix/legacy-app-service.yaml << 'EOF'
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

kubectl apply -f /opt/course/api-fix/legacy-app-service.yaml

# Create a network policy with deprecated API (if applicable)
cat > /opt/course/api-fix/network-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: legacy-app-netpol
  namespace: migration
spec:
  podSelector:
    matchLabels:
      app: legacy-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []
    ports:
    - protocol: TCP
      port: 80
  egress:
  - {}
EOF

kubectl apply -f /opt/course/api-fix/network-policy.yaml

echo "✅ Setup complete!"
echo "🎯 Context set to: cluster1"
echo "📁 Files created in: /opt/course/api-fix/"
echo "🚨 Legacy deployment with deprecated API version is now running"
echo "⚠️  Check for deprecation warnings in the cluster"
echo ""
echo "Your tasks:"
echo "1. Identify the deprecated API version in legacy-app deployment"
echo "2. Update to current stable API version"
echo "3. Ensure deployment maintains same functionality"
echo "4. Verify no deprecation warnings"
echo "5. Document the changes made"

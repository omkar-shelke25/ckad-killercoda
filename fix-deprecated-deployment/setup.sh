#!/bin/bash
set -e

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




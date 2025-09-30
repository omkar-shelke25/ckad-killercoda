#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="one-piece"
DEP="monkey.d.luffy"
MONITOR_DEP="crew-monitor"
BASE_IMAGE="public.ecr.aws/bitnami/kubectl:latest"
BASE_REPLICAS=2

# Create namespace if it doesn't exist
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Create the main Deployment (monkey.d.luffy) with kubectl image
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEP
  namespace: $NS
  labels:
    app: luffy
    crew: strawhat
spec:
  replicas: $BASE_REPLICAS
  selector:
    matchLabels:
      app: luffy
  template:
    metadata:
      labels:
        app: luffy
    spec:
      containers:
        - name: luffy-container
          image: $BASE_IMAGE
          command:
            - /bin/sh
            - -c
          args:
            - |
              echo "Luffy's pod starting..."
              echo "Trying to list deployments without proper RBAC..."
              while true; do
                kubectl get deployments --namespace=one-piece 2>&1 | head -5
                echo "---"
                sleep 60
              done
          resources:
            requests:
              cpu: "100m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
EOF

# Create ServiceAccount for crew-monitor (intentionally without RBAC)
kubectl create serviceaccount nami-navigator -n "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Create the crew-monitor deployment WITH ServiceAccount but WITHOUT Role/RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $MONITOR_DEP
  namespace: $NS
  labels:
    app: crew-monitor
    crew: strawhat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crew-monitor
  template:
    metadata:
      labels:
        app: crew-monitor
    spec:
      serviceAccountName: nami-navigator
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: monitor-container
          image: $BASE_IMAGE
          command:
            - /bin/sh
            - -c
          args:
            - |
              echo "Crew Monitor Starting..."
              echo "Attempting to list deployments in namespace one-piece..."
              while true; do
                kubectl get deployments --namespace=one-piece 2>&1
                if [ \$? -ne 0 ]; then
                  echo "ERROR: Failed to list deployments. Check RBAC permissions."
                else
                  echo "SUCCESS: Deployments listed successfully at \$(date)"
                fi
                sleep 30
              done
          resources:
            requests:
              cpu: "100m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsUser: 1000
            runAsGroup: 1000
EOF

# Wait for deployments to be ready
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true
kubectl -n "$NS" rollout status deploy/"$MONITOR_DEP" --timeout=120s || true

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo "Namespace: $NS"
echo ""
echo "Deployments created:"
echo "  1. $DEP - Running with default ServiceAccount (will show RBAC errors)"
echo "  2. $MONITOR_DEP - Running with 'nami-navigator' ServiceAccount (will show RBAC errors)"
echo ""
echo "Check the logs to see RBAC errors:"
echo "  kubectl logs -f deployment/$DEP -n $NS"
echo "  kubectl logs -f deployment/$MONITOR_DEP -n $NS"
echo ""
echo "Your task: Configure RBAC so these deployments can list deployments!"
echo "=========================================="

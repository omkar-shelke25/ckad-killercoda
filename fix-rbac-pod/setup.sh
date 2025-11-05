#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="qa-tools"
DEP="pod-explorer"
SA="sa-explorer"
BASE_IMAGE="public.ecr.aws/bitnami/kubectl:latest"
BASE_REPLICAS=1

# Create namespace if it doesn't exist
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount
kubectl create serviceaccount "$SA" -n "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Create 4 predefined Roles by the security team
# Role 1: Incorrect - Only ConfigMaps access
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-reader
  namespace: $NS
  labels:
    team: security
    purpose: config-access
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
EOF

# Role 2: Incorrect - Only Secrets access
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: $NS
  labels:
    team: security
    purpose: secret-access
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
EOF

# Role 3: CORRECT - Read-only Pod access
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: $NS
  labels:
    team: security
    purpose: pod-monitoring
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
EOF

# Role 4: Incorrect - Deployment access (but not pods)
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-viewer
  namespace: $NS
  labels:
    team: security
    purpose: deployment-monitoring
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
EOF

# Create the Deployment with the ServiceAccount but no RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEP
  namespace: $NS
  labels:
    app: pod-explorer
    environment: qa
spec:
  replicas: $BASE_REPLICAS
  selector:
    matchLabels:
      app: pod-explorer
  template:
    metadata:
      labels:
        app: pod-explorer
    spec:
      serviceAccountName: $SA
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: explorer-container
          image: $BASE_IMAGE
          command:
            - /bin/sh
            - -c
          args:
            - |
              echo "Pod Explorer Starting..."
              echo "Attempting to list pods in namespace $NS..."
              echo ""
              while true; do
                echo "=== Attempt at \$(date) ==="
                kubectl get pods --namespace=$NS 2>&1
                if [ \$? -ne 0 ]; then
                  echo "❌ ERROR: Failed to list pods. RBAC permissions missing!"
                  echo "Fix Required: Bind the correct Role to ServiceAccount '$SA'"
                else
                  echo "✅ SUCCESS: Pods listed successfully!"
                fi
                echo ""
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
            runAsUser: 1001
            runAsGroup: 1001
EOF

# Wait for deployment to be ready
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s || true

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo "Namespace: $NS"
echo ""
echo "Resources created:"
echo "  • Deployment: $DEP (using ServiceAccount: $SA)"
echo "  • ServiceAccount: $SA"
echo "  • 4 Predefined Roles by security team:"
echo "    - config-reader"
echo "    - secret-reader"
echo "    - pod-reader"
echo "    - deployment-viewer"
echo ""
echo "Current issue: Deployment cannot list pods due to missing RBAC!"
echo ""
echo "Check the logs to see the error:"
echo "  kubectl logs deployment/$DEP -n $NS"
echo ""
echo "Your task: Find and bind the correct Role!"
echo "=========================================="

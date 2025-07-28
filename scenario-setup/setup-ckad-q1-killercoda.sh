#!/bin/bash

# Script to set up CKAD Question 1 (Network Policy Restriction) in KillerCoda
# Checks Kubernetes version and creates namespace, pods, and NetworkPolicy
# Version-agnostic for compatibility with KillerCoda's Kubernetes version

set -e

# Variables
NAMESPACE="ckad-netpol"

# Function to check Kubernetes version
check_kubernetes_version() {
    echo "Checking Kubernetes version..."
    kubectl version --short | grep Server || echo "Warning: No server version found."
    KUBE_VERSION=$(kubectl version --short | grep Server | awk '{print $3}')
    echo "Kubernetes Server Version: $KUBE_VERSION"
}

# Function to set up namespace and resources
setup_namespace_and_resources() {
    echo "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" || echo "Namespace $NAMESPACE already exists."

    # Create app-pod (needs to be configured to comply with NetworkPolicy)
    echo "Creating app-pod"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: $NAMESPACE
  labels:
    app: app-pod
    # Missing role label; user must add role=allowed-app to comply
spec:
  containers:
  - name: app
    image: nginx:1.14
    ports:
    - containerPort: 80
EOF

    # Create frontend pod
    echo "Creating frontend-pod"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
  namespace: $NAMESPACE
  labels:
    role: frontend
spec:
  containers:
  - name: frontend
    image: nginx:1.14
    ports:
    - containerPort: 80
EOF

    # Create backend pod
    echo "Creating backend-pod"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  namespace: $NAMESPACE
  labels:
    role: backend
spec:
  containers:
  - name: backend
    image: redis:6
    ports:
    - containerPort: 6379
EOF

    # Create NetworkPolicy (simulates existing policy you cannot modify)
    echo "Creating NetworkPolicy"
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-app-pod
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      role: allowed-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: frontend
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 6379
EOF
}

# Function to verify setup
verify_setup() {
    echo "Verifying setup..."
    kubectl get namespaces | grep "$NAMESPACE" || { echo "Namespace $NAMESPACE not found!"; exit 1; }
    kubectl -n "$NAMESPACE" get pods -o wide
    kubectl -n "$NAMESPACE" get networkpolicy
    echo "Setup complete. You can now practice Question 1."
    echo "Task: Modify app-pod to allow ingress from and egress to pods labeled role=frontend and role=backend."
    echo "Hint: Check the NetworkPolicy and update app-pod labels (e.g., kubectl edit pod app-pod -n $NAMESPACE)."
    echo "Verify connectivity using: kubectl exec -n $NAMESPACE frontend-pod -- curl http://app-pod.$NAMESPACE.svc.cluster.local"
}

# Main execution
check_kubernetes_version
setup_namespace_and_resources
verify_setup

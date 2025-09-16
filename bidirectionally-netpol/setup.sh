#!/bin/bash
set -euo pipefail

echo "🚀 Setting up production environment..."

NAMESPACE="payment-platform"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "📦 Deploying microservices..."

# Create pods with intentionally incorrect labels (simulating misconfiguration)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend-service
  namespace: $NAMESPACE
  labels:
    tier: misconfigured
    version: v1.2.3
spec:
  containers:
  - name: frontend
    image: nginx:1.21-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: database-service
  namespace: $NAMESPACE
  labels:
    tier: misconfigured
    version: v2.1.0
spec:
  containers:
  - name: database
    image: nginx:1.21-alpine
    ports:
    - containerPort: 5432
---
apiVersion: v1
kind: Pod
metadata:
  name: payment-processor
  namespace: $NAMESPACE
  labels:
    tier: misconfigured
    component: payment
    version: v1.0.0
spec:
  containers:
  - name: processor
    image: nginx:1.21-alpine
    ports:
    - containerPort: 8080
EOF

echo "🛡️  Applying security NetworkPolicies..."

# Default deny all traffic
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all-traffic
  namespace: $NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Frontend service policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-service-policy
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            tier: payment
  egress:
    - to:
      - podSelector:
          matchLabels:
            tier: payment
EOF

# Database service policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-service-policy
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            tier: frontend
  egress:
    - to:
      - podSelector:
          matchLabels:
            tier: frontend
EOF

# Payment processor policy - allows communication with both frontend and database
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-processor-policy
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      tier: payment
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            tier: frontend
    - from:
      - podSelector:
          matchLabels:
            tier: database
  egress:
    - to:
      - podSelector:
          matchLabels:
            tier: frontend
    - to:
      - podSelector:
          matchLabels:
            tier: database
EOF

echo "✅ Environment ready!"
echo "📊 Current pod status:"
kubectl -n $NAMESPACE get pods --show-labels
echo ""
echo "🔍 NetworkPolicies configured:"
kubectl -n $NAMESPACE get networkpolicy
echo ""
echo "⚠️  Notice: Pods have incorrect labels and cannot communicate properly."
echo "🎯 Your task: Fix pod labels to align with existing NetworkPolicies."

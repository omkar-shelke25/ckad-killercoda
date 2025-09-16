#!/bin/bash
set -euo pipefail

echo "🚀 Preparing CKAD NetworkPolicy environment..."

NS="ckad-netpol"

# Create the namespace
kubectl create namespace $NS

echo "📦 Creating pods..."

# Create the 3 pods
kubectl -n $NS run web --image=nginx --port=80
kubectl -n $NS run db --image=nginx --port=80  
kubectl -n $NS run ckad-netpol-newpod --image=nginx --port=80 --labels="env=newpod"

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl -n $NS wait --for=condition=Ready pod --all --timeout=120s

echo "🔒 Creating NetworkPolicies..."

# Create default deny all policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: $NS
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Create web NetworkPolicy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-netpol
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      run: web
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            env: db
  egress:
    - to:
      - podSelector:
          matchLabels:
            env: db
EOF

# Create db NetworkPolicy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-netpol
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      run: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            run: web
  egress:
    - to:
      - podSelector:
          matchLabels:
            run: web
EOF

# Create allow-all policy for newpod
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      env: newpod
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            env: newpod
  egress:
    - to:
      - podSelector:
          matchLabels:
            env: newpod
EOF

echo "✅ Environment ready!"
echo "📋 Current pod status:"
kubectl -n $NS get pods -o wide

echo ""
echo "🔍 Current NetworkPolicies:"
kubectl -n $NS get networkpolicies

echo ""
echo "🎯 Task: Configure pod 'ckad-netpol-newpod' to communicate only with 'web' and 'db' pods"
echo "💡 Hint: Check existing NetworkPolicies and modify pod labels accordingly"

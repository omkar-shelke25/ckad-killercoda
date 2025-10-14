#!/bin/bash
set -euo pipefail

echo "🚀 Preparing CKAD NetworkPolicy environment..."

NS="netpol-challenge"
kubectl get ns $NS >/dev/null 2>&1 || kubectl create ns $NS

# Create 3 pods with intentionally incorrect labels
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
  namespace: $NS
  labels:
    type: frontend
spec:
  containers:
  - name: frontend
    image: nginx:1.20-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  namespace: $NS
  labels:
    type: backend
spec:
  containers:
  - name: backend
    image: nginx:1.20-alpine
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: target-pod
  namespace: $NS
  labels:
    type: target
spec:
  containers:
  - name: target
    image: nginx:1.20-alpine
    ports:
    - containerPort: 80
EOF

# Create 3 NetworkPolicies
# NetworkPolicy 1: Allows target-pod to receive traffic from pods with app=frontend and app=backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: target-ingress-policy
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      role: target-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
EOF

# NetworkPolicy 2: Allows target-pod to send traffic to pods with app=frontend and app=backend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: target-egress-policy
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      role: target-app
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
  - to: []  # Allow DNS resolution
    ports:
    - protocol: UDP
      port: 53
EOF

# NetworkPolicy 3: Default deny-all for pods with role=target-app (ensures only specified traffic is allowed)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: target-default-deny
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      role: target-app
  policyTypes:
  - Ingress
  - Egress
EOF

echo "✅ Environment ready!"
echo "📋 3 Pods created: frontend-pod, backend-pod, target-pod"
echo "📋 3 NetworkPolicies created: target-ingress-policy, target-egress-policy, target-default-deny"
echo "⚠️  All pods have incorrect labels - you need to fix them!"
echo "🚫 Remember: You CANNOT modify any NetworkPolicy!"

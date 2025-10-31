#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up NetworkPolicy lab environment..."

# --- CONFIGURATION ---
NS="production"
# ---------------------

# Create namespace
kubectl get ns "${NS}" >/dev/null 2>&1 || kubectl create namespace "${NS}"
echo "✅ Namespace '${NS}' ready."



# === DEPLOY PODS ===
echo "📦 Deploying pods in namespace '${NS}'..."

# Deploy web-server
kubectl run web-server -n ${NS} \
  --image=nginx \
  --labels="apps.io=web-server" \
  --port=80

# Deploy redis-server
kubectl run redis-server -n ${NS} \
  --image=redis \
  --labels="cache.io=redis-server" \
  --port=6379

# Deploy api-check (WITHOUT the required labels - user must add them)
kubectl run api-check -n ${NS} \
  --image=busybox \
  --port=8080 \
  --command -- sleep 3600

# Deploy allow-all pod (for testing purposes)
kubectl run allow-all -n ${NS} \
  --image=nginx \
  --labels="allowa-ll=allowa-ll" \
  --port=80

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod/web-server -n ${NS} --timeout=60s
kubectl wait --for=condition=Ready pod/redis-server -n ${NS} --timeout=60s
kubectl wait --for=condition=Ready pod/api-check -n ${NS} --timeout=60s
kubectl wait --for=condition=Ready pod/allow-all -n ${NS} --timeout=60s

# === CREATE SERVICES ===
echo "🌐 Creating services..."

kubectl expose pod web-server -n ${NS} \
  --port=80 \
  --target-port=80 \
  --name=web-server-svc

kubectl expose pod redis-server -n ${NS} \
  --port=6379 \
  --target-port=6379 \
  --name=redis-server-svc

kubectl expose pod api-check -n ${NS} \
  --port=8080 \
  --target-port=8080 \
  --name=api-check-svc

kubectl expose pod allow-all -n ${NS} \
  --port=80 \
  --name=allow-all-svc

echo "✅ Services created."

# === APPLY NETWORK POLICIES ===
echo "🔒 Applying NetworkPolicies..."

# Default deny-all policy (MUST be in production namespace)
cat <<'EOF' | kubectl apply -n ${NS} -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Utils network policy for api-check pod
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: utils-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      function: api-check
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              apps.io: web-server
        - podSelector:
            matchLabels:
              cache.io: redis-server
  egress:
    - to:
        - podSelector:
            matchLabels:
              apps.io: web-server
        - podSelector:
            matchLabels:
              cache.io: redis-server
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
EOF

# Web server network policy
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-server-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      apps.io: web-server
  policyTypes:
    - Ingress
    - Egress
  ingress:
  - from: 
    - podSelector:
        matchLabels:
          function: api-check
  egress:
    - to:
      - podSelector:
          matchLabels:
            function: api-check
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
             k8s-app: kube-dns
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
EOF

# Redis server network policy
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: redis-server-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      cache.io: redis-server
  policyTypes:
    - Ingress
    - Egress
  ingress:
  - from: 
    - podSelector:
        matchLabels:
          function: api-check
  egress:
    - to:
      - podSelector:
          matchLabels:
            function: api-check
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
             k8s-app: kube-dns
      ports:
      - protocol: TCP
        port: 53
      - protocol: UDP
        port: 53
EOF

# Allow-all network policy for testing
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-netpol
  namespace: production
spec:
  egress:
  - {}
  ingress:
  - {}
  podSelector:
    matchLabels:
      allowa-ll: allowa-ll
  policyTypes:
  - Ingress
  - Egress
EOF

echo "✅ NetworkPolicies applied."

# === SUMMARY ===
echo ""
echo "📋 Setup Complete!"
echo "-----------------------------------"
echo "Namespace: ${NS}"
echo ""
echo "Pods created:"
echo "  • web-server (labels: apps.io=web-server)"
echo "  • redis-server (labels: cache.io=redis-server)"
echo "  • api-check (NO function label - you must add it!)"
echo "  • allow-all (for testing)"
echo ""
echo "NetworkPolicies in place:"
echo "  • default-deny-all (blocks all traffic by default)"
echo "  • utils-network-policy (expects function=api-check label)"
echo "  • web-server-netpol (allows traffic from function=api-check)"
echo "  • redis-server-netpol (allows traffic from function=api-check)"
echo "  • allow-all-netpol (allows all for testing pod)"
echo ""
echo "⚠️  Current state: api-check CANNOT communicate with web-server or redis-server"
echo "🎯 Your goal: Enable communication by adding the correct label!"
echo "-----------------------------------"

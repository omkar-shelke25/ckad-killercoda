#!/usr/bin/env bash

echo "Preparing lab environment..."

# Namespaces
kubectl create namespace netpol-demo9 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-ns  --dry-run=client -o yaml | kubectl apply -f -

# source-pod in netpol-demo9
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: source-pod
  namespace: netpol-demo9
  labels:
    app: source
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sleep", "3600"]
EOF

# target-pod in external-ns (nginx serves on port 80)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: target-pod
  namespace: external-ns
  labels:
    app: target
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF

# Service for target-pod (students test via this DNS name)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: target-svc
  namespace: external-ns
spec:
  selector:
    app: target
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

# Wait for pods
kubectl wait --for=condition=Ready pod/source-pod -n netpol-demo9 --timeout=180s || true
kubectl wait --for=condition=Ready pod/target-pod  -n external-ns  --timeout=180s || true

# Pre-existing NetworkPolicies (students must NOT change these)
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: netpol-demo9
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress-source
  namespace: netpol-demo9
spec:
  podSelector:
    matchLabels:
      app: source
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: external-ns
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-netpol-demo9-source
  namespace: external-ns
spec:
  podSelector:
    matchLabels:
      app: target
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: netpol-demo9
      podSelector:
        matchLabels:
          app: source
    ports:
    - protocol: TCP
      port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress-target
  namespace: external-ns
spec:
  podSelector:
    matchLabels:
      app: target
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

echo ""
echo "======================================"
echo "Setup complete!"
echo "  netpol-demo9 → source-pod (alpine)"
echo "  external-ns  → target-pod (nginx) + target-svc"
echo ""
echo "Pre-existing NetworkPolicies applied."
echo "Your task: Create the 'external-target' NetworkPolicy."
echo "======================================"

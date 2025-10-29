#!/usr/bin/env bash
set -euo pipefail

# Create namespaces (idempotent)
kubectl create namespace netpol-demo9 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace external-ns --dry-run=client -o yaml | kubectl apply -f -

# Create source Pod in netpol-demo9
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
    image: public.ecr.aws/docker/library/alpine:latest
    command: ["sleep", "3600"]
    # keep it simple and editable; we'll use wget (busybox) for connectivity tests
EOF

# Create target Pod in external-ns
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
    image: public.ecr.aws/nginx/nginx:stable-alpine
    ports:
      - containerPort: 80
EOF

# Create ClusterIP Service for source-pod (optional, for testing)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: source-svc
  namespace: netpol-demo9
spec:
  selector:
    app: source
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
EOF

# Create ClusterIP Service for target-pod
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

# Wait for Pods to be ready (in their respective namespaces)
kubectl wait --for=condition=Ready pod/source-pod -n netpol-demo9 --timeout=180s || true
kubectl wait --for=condition=Ready pod/target-pod -n external-ns --timeout=180s || true

# Apply NetworkPolicies (deny-by-default + specific allows)
kubectl apply -f - <<'EOF'
# -----------------------
# netpol-demo9
# -----------------------
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

# -----------------------
# external-ns
# -----------------------
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

echo "Script complete."

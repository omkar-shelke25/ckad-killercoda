#!/usr/bin/env bash
set -euo pipefail

# Create namespace (idempotent)
kubectl create namespace ckad25 --dry-run=client -o yaml | kubectl apply -f -

# Create web Pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: ckad25
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: public.ecr.aws/nginx/nginx:stable-alpine
    ports:
      - containerPort: 80
EOF

# Create db Pod
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: ckad25
  labels:
    app: db
spec:
  containers:
  - name: postgres
    image: public.ecr.aws/docker/library/postgres:alpine
    env:
    - name: POSTGRES_PASSWORD
      value: password
    ports:
      - containerPort: 5432
EOF

# Create ckad25-newpod Pod (without label initially - student must add it)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ckad25-newpod
  namespace: ckad25
spec:
  containers:
  - name: alpine
    image: public.ecr.aws/docker/library/alpine:latest
    command: ["sleep", "3600"]
EOF

# Create Services for DNS resolution
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: ckad25
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: ckad25
spec:
  selector:
    app: db
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
EOF

# Wait for Pods to be ready
kubectl wait --for=condition=Ready pod/web -n ckad25 --timeout=180s || true
kubectl wait --for=condition=Ready pod/db -n ckad25 --timeout=180s || true
kubectl wait --for=condition=Ready pod/ckad25-newpod -n ckad25 --timeout=180s || true

# Apply existing NetworkPolicy (default deny + allow specific communication)
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: ckad25
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-db-communication
  namespace: ckad25
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: db
        - podSelector:
            matchLabels:
              app: newpod
      ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
        - podSelector:
            matchLabels:
              app: newpod
      ports:
        - protocol: TCP
          port: 5432
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-communication
  namespace: ckad25
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: web
        - podSelector:
            matchLabels:
              app: newpod
      ports:
        - protocol: TCP
          port: 5432
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: web
        - podSelector:
            matchLabels:
              app: newpod
      ports:
        - protocol: TCP
          port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: ckad25
spec:
  podSelector: {}
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

echo "Setup complete. NetworkPolicy is in place - you must label ckad25-newpod correctly!"

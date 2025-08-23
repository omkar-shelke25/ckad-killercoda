#!/bin/bash
set -euo pipefail

NS="netpol-demo8"

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Pre-create the pods exactly as specified, plus a tiny listener sidecar to ensure port-443 accepts TCP
# (nginx default image doesn't listen on 443 out-of-the-box).
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-port-pod
  namespace: netpol-demo8
  labels:
    app: multi-port
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - name: http
      containerPort: 80
      protocol: TCP
    - name: https
      containerPort: 443
      protocol: TCP
  - name: listener
    image: busybox:1.36
    command: ["/bin/sh","-c"]
    # Open simple TCP listeners on 80 and 443 so functional tests can connect.
    # If port 80 is already bound by nginx, nc will fail there but nginx will handle it; 443 will be handled by nc.
    args: ["(nc -lk -p 443 >/dev/null 2>&1 &) ; sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: netpol-demo8
  labels:
    role: frontend
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: admin
  namespace: netpol-demo8
  labels:
    role: admin
spec:
  containers:
  - name: busybox
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
EOF

# Wait for pods
kubectl -n "$NS" wait --for=condition=Ready pod/multi-port-pod --timeout=180s
kubectl -n "$NS" wait --for=condition=Ready pod/frontend --timeout=120s
kubectl -n "$NS" wait --for=condition=Ready pod/admin --timeout=120s

echo "✅ Environment ready: namespace '$NS' with pods 'multi-port-pod', 'frontend', and 'admin'."

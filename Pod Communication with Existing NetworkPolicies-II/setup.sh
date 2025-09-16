#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."

NS="ckad00018"
kubectl get ns $NS >/dev/null 2>&1 || kubectl create ns $NS

# Create pods with intentionally incorrect labels
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: $NS
  labels:
    wrong: label
spec:
  containers:
  - name: web
    image: busybox
    command: ["sh","-c","sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: $NS
  labels:
    wrong: label
spec:
  containers:
  - name: db
    image: busybox
    command: ["sh","-c","sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: ckad00018-newpod
  namespace: $NS
  labels:
    wrong: label
spec:
  containers:
  - name: newpod
    image: busybox
    command: ["sh","-c","sleep 3600"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-ckad00018
  namespace: $NS
spec:
  podSelector:
    matchLabels:
      app: newpod
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
          app: db
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: web
    - podSelector:
        matchLabels:
          app: db
EOF

echo "✅ Environment ready. Pods have wrong labels; fix them to align with existing NetworkPolicy."

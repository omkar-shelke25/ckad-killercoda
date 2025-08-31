#!/bin/bash
set -euo pipefail

echo "🚀 Preparing lab environment..."

# Namespace
kubectl get ns payment >/dev/null 2>&1 || kubectl create ns payment

# ServiceAccount
kubectl -n payment get sa payment-sa >/dev/null 2>&1 || kubectl -n payment create sa payment-sa

# Role
kubectl -n payment get role secret-accessor >/dev/null 2>&1 || cat <<EOF | kubectl -n payment apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-accessor
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
EOF

# RoleBinding
kubectl -n payment get rolebinding payment-secret-binding >/dev/null 2>&1 || kubectl -n payment create rolebinding payment-secret-binding --role=secret-accessor --serviceaccount=payment:payment-sa

# Deployment (misconfigured with default SA)
kubectl -n payment get deploy payment-api >/dev/null 2>&1 || cat <<EOF | kubectl -n payment apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      serviceAccountName: default
      containers:
      - name: payment-api
        image: nginx:1.25.3
        command: ["/bin/sh","-c","echo starting payment api && sleep 3600"]
EOF

echo "✅ Environment ready: Deployment 'payment-api' in 'payment' namespace uses default SA. Fix it to 'payment-sa'."

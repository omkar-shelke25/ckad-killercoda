#!/bin/bash
set -euo pipefail

NS="project-alpha"
SA="dev-user-1"
ROLE="config-reader"
RB="dev-user-1-binding"

echo "[SETUP] Creating namespace: $NS"
kubectl create ns "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[SETUP] Creating ServiceAccount: $SA"
kubectl -n "$NS" create sa "$SA" --dry-run=client -o yaml | kubectl apply -f -

echo "[SETUP] Creating a sample ConfigMap to test access"
kubectl -n "$NS" apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config
data:
  key: "value"
EOF

echo "[SETUP] Creating a Role with an intentional misconfiguration (uses singular 'configmap')"
kubectl -n "$NS" apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: $ROLE
rules:
- apiGroups: [""]
  resources: ["configmap"]  # <-- BUG: should be 'configmaps'
  verbs: ["get","list"]
EOF

echo "[SETUP] Binding the Role to the ServiceAccount"
kubectl -n "$NS" apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $RB
subjects:
- kind: ServiceAccount
  name: $SA
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $ROLE
EOF

echo "[SETUP] Verifying current (broken) permissions..."
kubectl auth can-i list configmaps \
  --as="system:serviceaccount:${NS}:${SA}" -n "$NS" || true

echo "Setup complete!
- Namespace: $NS
- ServiceAccount: $SA
- Role: $ROLE (intentionally wrong: uses 'configmap' instead of 'configmaps')
- RoleBinding: $RB

Your task: Fix the Role in-place so the SA can list ConfigMaps."

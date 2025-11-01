#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="default"
DEP_STABLE="frontend"
IMG_STABLE="nginx:1.19"
STABLE_REPLICAS=5
SVC="frontend-svc"

# 1) Create the stable deployment if missing
if ! kubectl -n "$NS" get deploy "$DEP_STABLE" >/dev/null 2>&1; then
  kubectl -n "$NS" create deployment "$DEP_STABLE" --image="$IMG_STABLE" \
    --dry-run=client -o yaml | \
  kubectl -n "$NS" apply -f -

  # Ensure labels: app=frontend, version=v1
  kubectl -n "$NS" patch deploy "$DEP_STABLE" --type='json' -p='[
    {"op":"add","path":"/spec/template/metadata/labels","value":{"app":"frontend","version":"v1"}},
    {"op":"add","path":"/spec/selector/matchLabels","value":{"app":"frontend"}},
    {"op":"add","path":"/metadata/labels","value":{"app":"frontend"}}
  ]' || true

  kubectl -n "$NS" scale deploy "$DEP_STABLE" --replicas="$STABLE_REPLICAS"
fi

# 2) Create a ClusterIP service selecting app=frontend (if missing)
if ! kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1; then
cat <<EOF | kubectl -n "$NS" apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${SVC}
  labels:
    app: frontend
spec:
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF
fi

# Make sure container exposes port 80 (nginx default)
kubectl -n "$NS" patch deploy "$DEP_STABLE" --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/ports","value":[{"containerPort":80}]}
]' || true

kubectl -n "$NS" rollout status deploy/"$DEP_STABLE" --timeout=180s || true
echo "Setup complete: stable '${DEP_STABLE}' = ${IMG_STABLE} with ${STABLE_REPLICAS} replicas; Service '${SVC}' selects app=frontend."


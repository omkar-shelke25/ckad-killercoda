#!/bin/bash
set -euo pipefail

NS="apps"
DEP="app-workload"
CM="app-config"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 1) ConfigMap exists with exact keys/values
kubectl -n "$NS" get configmap "$CM" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in '$NS'."
MODE=$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.APP_MODE}')
PORT=$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.APP_PORT}')
[[ "$MODE" == "production" ]] || fail "ConfigMap '$CM'.APP_MODE must be 'production'."
[[ "$PORT" == "8080" ]] || fail "ConfigMap '$CM'.APP_PORT must be '8080'."

# 2) Deployment exists with 2 replicas and nginx image
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "2" ]] || fail "Deployment '$DEP' must have replicas=2."
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == nginx:* || "$IMG" == *"/nginx:"* ]] || fail "Deployment must use an nginx image (found '$IMG')."

# 3) Volume mount of ConfigMap at /etc/appconfig
MOUNT=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.containers[0].volumeMounts[] | select(.mountPath=="/etc/appconfig") | .name' | head -n1)
[[ -n "$MOUNT" ]] || fail "Container must mount ConfigMap at /etc/appconfig."
VOL_CM=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r --arg v "$MOUNT" '.spec.template.spec.volumes[] | select(.name==$v) | .configMap.name')
[[ "$VOL_CM" == "$CM" ]] || fail "Mounted volume must reference ConfigMap '$CM'."

# 4) Readiness probe checks file contents via exec
HAS_PROBE=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.containers[0].readinessProbe.exec.command | join(" ")' | grep -F "/etc/appconfig/APP_MODE" || true)
[[ -n "$HAS_PROBE" ]] || fail "readinessProbe (exec) must validate files under /etc/appconfig."

# 5) (Optional) pods become Ready
if ! kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=90s >/dev/null 2>&1; then
  fail "Deployment '$DEP' did not become Ready. Check ConfigMap values and readinessProbe."
fi

pass "Verification successful! Workload meets all requirements!"

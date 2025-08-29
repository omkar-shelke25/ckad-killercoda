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
[[ "$MODE" == "production" ]] || fail "ConfigMap '$CM'.APP_MODE must be 'production' (found '$MODE')."
[[ "$PORT" == "8080" ]] || fail "ConfigMap '$CM'.APP_PORT must be '8080' (found '$PORT')."
pass "ConfigMap '$CM' has correct values: APP_MODE=$MODE, APP_PORT=$PORT"

# 2) Deployment exists with 2 replicas and nginx image
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "2" ]] || fail "Deployment '$DEP' must have replicas=2 (found '$REPLICAS')."
pass "Deployment '$DEP' has correct replica count: $REPLICAS"

# Fixed nginx image validation - accepts nginx, nginx:tag, or registry/nginx:tag
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMG" == "nginx" || "$IMG" == nginx:* || "$IMG" == */nginx || "$IMG" == */nginx:* ]]; then
    pass "Deployment uses nginx image: $IMG"
else
    fail "Deployment must use an nginx image (found '$IMG')."
fi

# 3) Volume mount of ConfigMap at /etc/appconfig
MOUNT=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.containers[0].volumeMounts[]? | select(.mountPath=="/etc/appconfig") | .name' | head -n1)
[[ -n "$MOUNT" ]] || fail "Container must mount ConfigMap at /etc/appconfig."
VOL_CM=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r --arg v "$MOUNT" '.spec.template.spec.volumes[]? | select(.name==$v) | .configMap.name')
[[ "$VOL_CM" == "$CM" ]] || fail "Mounted volume must reference ConfigMap '$CM' (found '$VOL_CM')."
pass "ConfigMap '$CM' is correctly mounted at /etc/appconfig via volume '$MOUNT'"

# 4) Readiness probe checks file contents via exec
PROBE_CMD=$(kubectl -n "$NS" get deploy "$DEP" -o json | jq -r '.spec.template.spec.containers[0].readinessProbe.exec.command[]?' | tr '\n' ' ')
if [[ "$PROBE_CMD" == *"/etc/appconfig/APP_MODE"* && "$PROBE_CMD" == *"/etc/appconfig/APP_PORT"* && "$PROBE_CMD" == *"grep"* ]]; then
    pass "Readiness probe validates ConfigMap files: $PROBE_CMD"
else
    fail "readinessProbe (exec) must validate files under /etc/appconfig using grep command."
fi

# 5) Deployment rollout status
echo "⏳ Checking deployment rollout status..."
if kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=90s >/dev/null 2>&1; then
    READY_PODS=$(kubectl -n "$NS" get pods -l app="$DEP" --field-selector=status.phase=Running -o json | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
    [[ "$READY_PODS" == "2" ]] || fail "Expected 2 ready pods, found $READY_PODS ready pods."
    pass "Deployment '$DEP' is running with $READY_PODS/$REPLICAS pods ready!"
else
    fail "Deployment '$DEP' did not become Ready within 90s. Check ConfigMap values and readinessProbe."
fi

echo ""
pass "🎉 Verification successful! All requirements met:"
echo "   ✓ Namespace: $NS"
echo "   ✓ ConfigMap: $CM (APP_MODE=production, APP_PORT=8080)"
echo "   ✓ Deployment: $DEP (2 replicas, nginx image)"
echo "   ✓ Volume mount: /etc/appconfig"
echo "   ✓ Readiness probe: validates ConfigMap files"
echo "   ✓ Status: All pods ready"

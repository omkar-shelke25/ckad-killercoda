#!/bin/bash
set -euo pipefail

NS="default"
CM="app-config"
POD="app-pod"
IMG="nginx:1.29.0"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) ConfigMap exists with required keys/values
kubectl -n "$NS" get cm "$CM" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in namespace '$NS'."
MODE=$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.APP_MODE}')
VER=$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.APP_VERSION}')
[[ "$MODE" == "production" ]] || fail "APP_MODE must be 'production' (found '$MODE')."
[[ "$VER" == "1.0" ]] || fail "APP_VERSION must be '1.0' (found '$VER')."

# 2) Pod exists and uses correct image
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Pod image must be '$IMG' (found '$PIMG')."

# 3) Pod is Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=90s >/dev/null 2>&1 || \
  fail "Pod '$POD' did not become Ready."

# 4) Spec uses envFrom or configMapKeyRef with app-config
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)

HAS_ENVFROM=$(echo "$JSON" | jq -r '.spec.containers[0].envFrom[]? | select(.configMapRef.name=="app-config") | "yes"' | head -n1)
HAS_KEYREF_MODE=$(echo "$JSON" | jq -r '.spec.containers[0].env[]? | select(.name=="APP_MODE") | select(.valueFrom.configMapKeyRef.name=="app-config") | "yes"' | head -n1)
HAS_KEYREF_VER=$(echo "$JSON" | jq -r '.spec.containers[0].env[]? | select(.name=="APP_VERSION") | select(.valueFrom.configMapKeyRef.name=="app-config") | "yes"' | head -n1)

if [[ "$HAS_ENVFROM" == "yes" ]]; then
  : # ok
elif [[ "$HAS_KEYREF_MODE" == "yes" && "$HAS_KEYREF_VER" == "yes" ]]; then
  : # ok
else
  fail "Pod must inject env vars from ConfigMap 'app-config' (envFrom or key-by-key)."
fi

# 5) Runtime env actually contains expected values
OUT=$(kubectl -n "$NS" exec "$POD" -- /bin/sh -c 'echo "APP_MODE=$APP_MODE"; echo "APP_VERSION=$APP_VERSION"')
echo "$OUT" | grep -q '^APP_MODE=production$' || fail "Runtime APP_MODE is incorrect. Got: $(echo "$OUT" | grep APP_MODE)"
echo "$OUT" | grep -q '^APP_VERSION=1.0$'    || fail "Runtime APP_VERSION is incorrect. Got: $(echo "$OUT" | grep APP_VERSION)"

pass "Verification successful! ConfigMap keys are correctly exposed as environment variables in '$POD'."

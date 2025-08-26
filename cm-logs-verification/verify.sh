#!/bin/bash
set -euo pipefail

NS="olly"
CM="message-config"
POD="message-pod"
IMG="busybox:1.37.0"
EXPECTED="Hello, Kubernetes"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 1) ConfigMap exists with correct key/value
kubectl -n "$NS" get cm "$CM" >/dev/null 2>&1 || fail "ConfigMap '$CM' not found in '$NS'."
VAL=$(kubectl -n "$NS" get cm "$CM" -o jsonpath='{.data.message}')
[[ "$VAL" == "$EXPECTED" ]] || fail "ConfigMap '$CM'.message must equal '$EXPECTED' (found '$VAL')."

# 2) Pod exists, image correct, env wired via configMapKeyRef
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Pod image must be '$IMG' (found '$PIMG')."

JSON=$(kubectl -n "$NS" get pod "$POD" -o json)
HAS_ENV=$(echo "$JSON" | jq -r '.spec.containers[0].env[]? | select(.name=="MESSAGE") | select(.valueFrom.configMapKeyRef.name=="message-config" and .valueFrom.configMapKeyRef.key=="message") | "yes"' | head -n1)
[[ "$HAS_ENV" == "yes" ]] || fail "Env var MESSAGE must come from configMapKeyRef message-config/message."

# 3) Pod Running/Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=90s >/dev/null 2>&1 || {
  PHASE=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}')
  [[ "$PHASE" == "Running" ]] || fail "Pod '$POD' is not Ready or Running (phase=$PHASE)."
}

# 4) Logs contain the expected value
OUT=$(kubectl -n "$NS" logs "$POD" --tail=10 || true)
echo "$OUT" | grep -q "$EXPECTED" || fail "Pod logs do not contain expected message '$EXPECTED'."

pass "Verification successful! MESSAGE env var is set from ConfigMap and visible in logs."

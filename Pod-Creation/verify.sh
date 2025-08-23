#!/bin/bash
set -euo pipefail

NS="default"
POD="pod1"
CTR="pod1-container"
IMG="httpd:2.4.41-alpine"
SCRIPT="/opt/course/2/pod1-status-command.sh"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."

# 2) Container name & image
CNAME="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].name}')"
[ "$CNAME" = "$CTR" ] || fail "Container name is '$CNAME', expected '$CTR'."

CIMAGE="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')"
[ "$CIMAGE" = "$IMG" ] || fail "Container image is '$CIMAGE', expected '$IMG'."
pass "Pod spec matches: container '$CTR' using image '$IMG'."

# 3) Pod Running/Ready
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=180s >/dev/null 2>&1 || fail "Pod '$POD' did not become Ready."
PHASE="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}')"
[ "$PHASE" = "Running" ] || fail "Pod phase is '$PHASE', expected 'Running'."
pass "Pod is Running and Ready."

# 4) Script exists, executable, and uses kubectl
[ -f "$SCRIPT" ] || fail "Script '$SCRIPT' not found."
[ -x "$SCRIPT" ] || fail "Script '$SCRIPT' is not executable."
grep -q "kubectl" "$SCRIPT" || fail "Script '$SCRIPT' must use kubectl."
pass "Script exists, is executable, and uses kubectl."

# 5) Script prints the same phase as kubectl
OUT="$("$SCRIPT" 2>/dev/null | tr -d '\r' | tr -d '\n')"
[ -n "$OUT" ] || fail "Script output is empty; must print pod phase."
if [ "$OUT" != "$PHASE" ]; then
  fail "Script output '$OUT' does not match current phase '$PHASE'."
fi
pass "Script prints the correct pod phase: $OUT."

echo "✅ Verification successful! Pod and status script meet all requirements."

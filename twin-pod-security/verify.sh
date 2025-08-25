#!/bin/bash
set -euo pipefail

NS="sec-ctx"
POD="twin-uid"

pass(){ echo "✓ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace check
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# Pod check
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in '$NS'."
pass "Pod '$POD' exists in '$NS'"

# Container names
names=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}')
echo "$names" | grep -qx "preproc" || fail "Container 'preproc' not found."
echo "$names" | grep -qx "shipper" || fail "Container 'shipper' not found."
[ "$(echo "$names" | wc -l | tr -d ' ')" = "2" ] || fail "Pod must have exactly two containers."
pass "Found containers: preproc, shipper"

# Same image check
img_pre=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[?(@.name=="preproc")].image}')
img_ship=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[?(@.name=="shipper")].image}')
[ "$img_pre" = "$img_ship" ] || fail "Containers must use the same image (got $img_pre vs $img_ship)."
pass "Both containers use same image: $img_pre"

# runAsUser checks
uid_pre=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[?(@.name=="preproc")].securityContext.runAsUser}')
uid_ship=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[?(@.name=="shipper")].securityContext.runAsUser}')
[ "$uid_pre" = "1000" ] || fail "preproc.runAsUser should be 1000 (got '$uid_pre')."
[ "$uid_ship" = "2000" ] || fail "shipper.runAsUser should be 2000 (got '$uid_ship')."
pass "runAsUser values correct: preproc=1000, shipper=2000"

# fsGroup check
fs_group=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.fsGroup}')
[ -n "$fs_group" ] || fail "Pod-level fsGroup not set."
pass "Pod fsGroup set: $fs_group"

# ✅ Container state check
states=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{range .status.containerStatuses[*]}{.name}:{.state.running.startedAt}{"\n"}{end}')
while IFS= read -r line; do
  cname=$(echo "$line" | cut -d: -f1)
  started=$(echo "$line" | cut -d: -f2)
  [ -n "$started" ] || fail "Container '$cname' is not running."
  pass "Container '$cname' is running (started at $started)"
done <<< "$states"

echo "🎉 All checks passed!"

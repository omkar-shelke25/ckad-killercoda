#!/bin/bash
set -euo pipefail

NS="security"
POD="secure-app-pod"
CTR="app-container"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "🔎 Verifying Pod/Container security context..."

# Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."

# Pod reaches Ready/Running
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=120s >/dev/null 2>&1 || fail "Pod '$POD' did not become Ready."
PHASE="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}')"
[ "$PHASE" = "Running" ] || fail "Pod phase is '$PHASE', expected 'Running'."
pass "Pod is Running and Ready."

# ----- Pod-level securityContext checks -----
RUN_AS_USER="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.runAsUser}')"
RUN_AS_GROUP="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.runAsGroup}')"
RUN_AS_NONROOT="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.runAsNonRoot}')"

[ "$RUN_AS_USER" = "1000" ]   || fail "Pod runAsUser='$RUN_AS_USER', expected '1000'."
[ "$RUN_AS_GROUP" = "3000" ]  || fail "Pod runAsGroup='$RUN_AS_GROUP', expected '3000'."
[ "$RUN_AS_NONROOT" = "true" ] || fail "Pod runAsNonRoot='$RUN_AS_NONROOT', expected 'true'."

pass "Pod securityContext has runAsUser=1000, runAsGroup=3000, runAsNonRoot=true."

# ----- Container-level overrides (must not weaken) -----
# readOnlyRootFilesystem must be true at container level
RO_ROOTFS="$(kubectl -n "$NS" get pod "$POD" -o jsonpath="{.spec.containers[?(@.name=='$CTR')].securityContext.readOnlyRootFilesystem}")"
[ "$RO_ROOTFS" = "true" ] || fail "Container readOnlyRootFilesystem='$RO_ROOTFS', expected 'true'."
pass "Container securityContext has readOnlyRootFilesystem=true."

# If container.runAsNonRoot is set, it must not be false (true or empty is acceptable)
CTR_RANR="$(kubectl -n "$NS" get pod "$POD" -o jsonpath="{.spec.containers[?(@.name=='$CTR')].securityContext.runAsNonRoot}")"
if [[ -z "$CTR_RANR" ]]; then
  pass "Container runAsNonRoot not set (inherits Pod-level true)."
elif [[ "$CTR_RANR" = "true" ]]; then
  pass "Container runAsNonRoot=true (explicit override consistent with Pod-level)."
else
  fail "Container runAsNonRoot='$CTR_RANR' weakens Pod policy; must be unset or true."
fi

# ----- Effective runtime identity checks -----
UID_VAL="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'id -u')"
GID_VAL="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'id -g')"
[ "$UID_VAL" = "1000" ] || fail "Runtime UID is '$UID_VAL', expected '1000'."
[ "$GID_VAL" = "3000" ] || fail "Runtime GID is '$GID_VAL', expected '3000'."
pass "Runtime identity matches: uid=1000 gid=3000."

# ----- Root FS must be read-only -----
OUT="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'touch /newfile' 2>&1 || true)"
echo "$OUT" | grep -qi "read-only file system" || fail "Expected 'Read-only file system' error when touching '/newfile'. Output was: $OUT"
EXISTS="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'test -e /newfile && echo exists || echo missing')"
[ "$EXISTS" = "missing" ] || fail "/newfile unexpectedly exists."
pass "Root filesystem is read-only; write attempt failed as expected."

echo "🎉 Verification successful! Pod- and container-level SecurityContext are correctly enforced."

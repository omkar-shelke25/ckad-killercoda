#!/bin/bash
set -euo pipefail

NS="security"
POD="secure-app-pod"
CTR="app-container"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."

# Pod reaches Ready/Running
kubectl -n "$NS" wait --for=condition=Ready pod/"$POD" --timeout=120s >/dev/null 2>&1 || fail "Pod '$POD' did not become Ready."
PHASE="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}')"
[ "$PHASE" = "Running" ] || fail "Pod phase is '$PHASE', expected 'Running'."
pass "Pod is Running and Ready."

# Check Pod-level securityContext runAsUser/runAsGroup
RUN_AS_USER="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.runAsUser}')"
RUN_AS_GROUP="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.securityContext.runAsGroup}')"
[ "$RUN_AS_USER" = "1000" ] || fail "Pod runAsUser='$RUN_AS_USER', expected '1000'."
[ "$RUN_AS_GROUP" = "3000" ] || fail "Pod runAsGroup='$RUN_AS_GROUP', expected '3000'."
pass "Pod securityContext has runAsUser=1000 and runAsGroup=3000."

# Check container-level readOnlyRootFilesystem
RO_ROOTFS="$(kubectl -n "$NS" get pod "$POD" -o jsonpath="{.spec.containers[?(@.name=='$CTR')].securityContext.readOnlyRootFilesystem}")"
[ "$RO_ROOTFS" = "true" ] || fail "Container readOnlyRootFilesystem='$RO_ROOTFS', expected 'true'."
pass "Container securityContext has readOnlyRootFilesystem=true."

# Confirm effective UID/GID inside container
UID_VAL="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'id -u')"
GID_VAL="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'id -g')"
[ "$UID_VAL" = "1000" ] || fail "Runtime UID is '$UID_VAL', expected '1000'."
[ "$GID_VAL" = "3000" ] || fail "Runtime GID is '$GID_VAL', expected '3000'."
pass "Runtime identity matches: uid=1000 gid=3000."

# Writing to root filesystem must fail
OUT="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'touch /newfile' 2>&1 || true)"
echo "$OUT" | grep -qi "read-only file system" || fail "Expected 'Read-only file system' error when touching '/newfile'. Output was: $OUT"
# Ensure file not created
EXISTS="$(kubectl -n "$NS" exec "$POD" -c "$CTR" -- sh -c 'test -e /newfile && echo exists || echo missing')"
[ "$EXISTS" = "missing" ] || fail "/newfile unexpectedly exists."
pass "Root filesystem is read-only; write attempt failed as expected."

echo "✅ Verification successful! Pod-level and container-level SecurityContext are correctly enforced."

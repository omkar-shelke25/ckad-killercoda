#!/bin/bash
set -euo pipefail

NS="default"
DEP="api-server"
EXPECT_IMAGE="nginx:1.26.0"
EXPECT_REPLICAS="5"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 2) Deployment must be unpaused now
PAUSED="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.paused}' 2>/dev/null || true)"
if [[ -n "${PAUSED}" && "${PAUSED}" != "false" ]]; then
  fail "Deployment '$DEP' must be resumed (spec.paused=false). Found: '${PAUSED}'."
fi

# 3) Image should be nginx:1.26.0
IMG="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')"
[[ "$IMG" == "$EXPECT_IMAGE" ]] || fail "Expected image '$EXPECT_IMAGE' but found '$IMG'."

# 4) Replicas should be 5 and rollout should be Ready
REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "$REPLICAS" == "$EXPECT_REPLICAS" ]] || fail "Expected replicas=$EXPECT_REPLICAS but found '${REPLICAS:-<none>}'."

kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become Ready."

READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "$READY" == "$EXPECT_REPLICAS" ]] || fail "Expected $EXPECT_REPLICAS ready replicas but found '${READY:-0}'."

# 5) Ensure there was at least one rollout update (revision >= 2)
REV="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
REV="${REV:-0}"
if ! [[ "$REV" =~ ^[0-9]+$ ]]; then
  fail "Revision is not numeric (found '${REV}')."
fi
(( REV >= 2 )) || fail "Expected revision >= 2 (found '${REV}')."

pass "Verification successful! Deployment '$DEP' is resumed, image '$EXPECT_IMAGE', replicas=$EXPECT_REPLICAS, ready=$READY (revision $REV)."

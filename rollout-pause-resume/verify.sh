#!/bin/bash
set -euo pipefail

NS="default"
DEP="api-server"
GOOD_IMAGE="nginx:1.25.3"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

PAUSED=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.paused}')
[[ -z "$PAUSED" || "$PAUSED" == "false" ]] || fail "Deployment '$DEP' must be resumed (spec.paused=false)."

IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$IMG" == "$GOOD_IMAGE" ]] || fail "Deployment '$DEP' image must be '$GOOD_IMAGE' (found '$IMG')."

REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
READY=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "$REPLICAS" == "3" ]] || fail "Deployment '$DEP' must have replicas=3 (found $REPLICAS)."
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 || \
  fail "Deployment '$DEP' did not become Ready."
[[ "$READY" == "3" ]] || fail "Deployment '$DEP' should have 3 ready replicas (found ${READY:-0})."

REV=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
[[ -n "$REV" && "$REV" -ge 2 ]] || fail "Deployment '$DEP' should have revision >= 2 (found '${REV:-<none>}')."

pass "Verification successful! Deployment '$DEP' is resumed, rolled back to '$GOOD_IMAGE', and ready with 3 replicas."

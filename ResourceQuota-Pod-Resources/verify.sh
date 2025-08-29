#!/bin/bash
set -euo pipefail

NS="production-apps"
RQ="app-quota"
DEP="web-server"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) ResourceQuota exists with exact hard limits
kubectl -n "$NS" get resourcequota "$RQ" >/dev/null 2>&1 || fail "ResourceQuota '$RQ' not found in '$NS'."

PODS_HARD="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.spec.hard.pods}')"
REQ_CPU_HARD="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.spec.hard.requests\.cpu}')"
REQ_MEM_HARD="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.spec.hard.requests\.memory}')"
LIM_CPU_HARD="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.spec.hard.limits\.cpu}')"
LIM_MEM_HARD="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.spec.hard.limits\.memory}')"

[[ "$PODS_HARD" == "4" ]] || fail "ResourceQuota pods must be 4 (found '$PODS_HARD')."
[[ "$REQ_CPU_HARD" == "2000m" ]] || fail "requests.cpu must be 2000m (found '$REQ_CPU_HARD')."
[[ "$REQ_MEM_HARD" == "4Gi" ]] || fail "requests.memory must be 4Gi (found '$REQ_MEM_HARD')."
[[ "$LIM_CPU_HARD" == "4000m" ]] || fail "limits.cpu must be 4000m (found '$LIM_CPU_HARD')."
[[ "$LIM_MEM_HARD" == "8Gi" ]] || fail "limits.memory must be 8Gi (found '$LIM_MEM_HARD')."

# 3) Deployment exists with 3 replicas
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "$REPLICAS" == "3" ]] || fail "Deployment replicas must be 3 (found '$REPLICAS')."

# 4) Container image is nginx (any tag OK)
IMAGE="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')"
case "$IMAGE" in
  nginx:*|*/nginx:*) : ;;
  nginx) : ;;
  *) fail "Container image must be an nginx image (found '$IMAGE')." ;;
esac

# 5) Verify requests/limits on the container
REQ_CPU="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')"
REQ_MEM="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')"
LIM_CPU="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')"
LIM_MEM="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')"

[[ "$REQ_CPU" == "200m" ]] || fail "requests.cpu must be 200m (found '$REQ_CPU')."
[[ "$REQ_MEM" == "256Mi" ]] || fail "requests.memory must be 256Mi (found '$REQ_MEM')."
[[ "$LIM_CPU" == "500m" ]] || fail "limits.cpu must be 500m (found '$LIM_CPU')."
[[ "$LIM_MEM" == "512Mi" ]] || fail "limits.memory must be 512Mi (found '$LIM_MEM')."

# 6) Rollout and pod status
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 || \
  fail "Deployment '$DEP' did not become Ready."

READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "$READY" == "3" ]] || fail "Expected 3 ready replicas (found '${READY:-0}')."

# 7) Quota enforcement basic check: used pods should be <= 4 (ideally 3)
USED_PODS="$(kubectl -n "$NS" get resourcequota "$RQ" -o jsonpath='{.status.used.pods}' 2>/dev/null || true)"
if [[ -n "$USED_PODS" ]]; then
  # When controller populated, ensure usage within quota
  if ! [[ "$USED_PODS" =~ ^[0-9]+$ ]]; then
    fail "ResourceQuota status.used.pods is not numeric (found '$USED_PODS')."
  fi
  (( USED_PODS <= 4 )) || fail "ResourceQuota pods usage exceeds limit (used=$USED_PODS, limit=4)."
fi

pass "Verification successful! Namespace, ResourceQuota, and Deployment meet all requirements."

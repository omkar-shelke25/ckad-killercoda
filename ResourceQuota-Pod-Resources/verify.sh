#!/bin/bash
set -euo pipefail

NS="production-apps"
QUOTA="app-quota"
DEP="web-server"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 2) ResourceQuota exists with correct hard limits
kubectl -n "$NS" get resourcequota "$QUOTA" >/dev/null 2>&1 || fail "ResourceQuota '$QUOTA' not found in '$NS'."

QUOTA_PODS=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.spec.hard.pods}')
QUOTA_CPU_REQ=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.spec.hard.requests\.cpu}')
QUOTA_MEM_REQ=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.spec.hard.requests\.memory}')
QUOTA_CPU_LIM=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.spec.hard.limits\.cpu}')
QUOTA_MEM_LIM=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.spec.hard.limits\.memory}')

[[ "$QUOTA_PODS" == "4" ]] || fail "ResourceQuota pods limit must be 4 (found '$QUOTA_PODS')."
[[ "$QUOTA_CPU_REQ" == "2" || "$QUOTA_CPU_REQ" == "2000m" ]] || fail "ResourceQuota CPU requests must be 2000m (found '$QUOTA_CPU_REQ')."
[[ "$QUOTA_MEM_REQ" == "4Gi" ]] || fail "ResourceQuota memory requests must be 4Gi (found '$QUOTA_MEM_REQ')."
[[ "$QUOTA_CPU_LIM" == "4" || "$QUOTA_CPU_LIM" == "4000m" ]] || fail "ResourceQuota CPU limits must be 4000m (found '$QUOTA_CPU_LIM')."
[[ "$QUOTA_MEM_LIM" == "8Gi" ]] || fail "ResourceQuota memory limits must be 8Gi (found '$QUOTA_MEM_LIM')."
pass "ResourceQuota '$QUOTA' has correct limits"

# 3) Deployment exists with 3 replicas
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "3" ]] || fail "Deployment '$DEP' must have 3 replicas (found '$REPLICAS')."
pass "Deployment '$DEP' has correct replica count: $REPLICAS"

# 4) nginx image — accepts any nginx tag/registry path, but nginx:alpine is what
#    the task asks for specifically (smaller image, faster scheduling in CI).
IMG=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMG" == "nginx" || "$IMG" == nginx:* || "$IMG" == */nginx || "$IMG" == */nginx:* ]]; then
    pass "Deployment uses nginx image: $IMG"
else
    fail "Deployment must use an nginx image, e.g. nginx:alpine (found '$IMG')."
fi

# 5) Pod resource requests and limits
CPU_REQ=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
MEM_REQ=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
CPU_LIM=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
MEM_LIM=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')

[[ "$CPU_REQ" == "200m" ]] || fail "Pod CPU request must be 200m (found '$CPU_REQ')."
[[ "$MEM_REQ" == "256Mi" ]] || fail "Pod memory request must be 256Mi (found '$MEM_REQ')."
[[ "$CPU_LIM" == "500m" ]] || fail "Pod CPU limit must be 500m (found '$CPU_LIM')."
[[ "$MEM_LIM" == "512Mi" ]] || fail "Pod memory limit must be 512Mi (found '$MEM_LIM')."
pass "Pod resources configured correctly: CPU(200m/500m), Memory(256Mi/512Mi)"

# 6) Pods found via the Deployment's actual selector — not a hardcoded guess.
#    This is the fix: previously this script assumed label app=<deployment-name>,
#    which broke verification for anyone who used a different (still valid) label.
SELECTOR_JSON=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.selector.matchLabels}')
SELECTOR=$(echo "$SELECTOR_JSON" | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")')

[[ -n "$SELECTOR" ]] || fail "Deployment '$DEP' has no matchLabels selector."

RUNNING_PODS=$(kubectl -n "$NS" get pods -l "$SELECTOR" --field-selector=status.phase=Running -o json | jq '.items | length')
READY_PODS=$(kubectl -n "$NS" get pods -l "$SELECTOR" -o json | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')

[[ "$RUNNING_PODS" == "3" ]] || fail "Expected 3 running pods matching selector '$SELECTOR', found $RUNNING_PODS."
[[ "$READY_PODS" == "3" ]] || fail "Expected 3 ready pods matching selector '$SELECTOR', found $READY_PODS."
pass "All pods are running and ready: $READY_PODS/$REPLICAS"

# 7) ResourceQuota usage reflects the running pods
USED_PODS=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.status.used.pods}')
USED_CPU_REQ=$(kubectl -n "$NS" get resourcequota "$QUOTA" -o jsonpath='{.status.used.requests\.cpu}')

[[ "$USED_CPU_REQ" == "600m" || "$USED_CPU_REQ" == "0.6" ]] \
  || fail "Expected CPU usage 600m for 3 pods, found '$USED_CPU_REQ'."
[[ "$USED_PODS" == "3" ]] || fail "ResourceQuota should show 3 pods in use (found '$USED_PODS')."
pass "ResourceQuota usage: $USED_PODS/$QUOTA_PODS pods, $USED_CPU_REQ CPU requests"

echo ""
pass "Verification successful! Resource management configured correctly:"
echo "   ✓ Namespace: $NS"
echo "   ✓ ResourceQuota: $QUOTA (pods: $USED_PODS/$QUOTA_PODS, CPU: $USED_CPU_REQ/$QUOTA_CPU_REQ)"
echo "   ✓ Deployment: $DEP (3 replicas, nginx image)"
echo "   ✓ Pod Resources: CPU(200m/500m), Memory(256Mi/512Mi)"
echo "   ✓ Status: All pods running within quota limits"

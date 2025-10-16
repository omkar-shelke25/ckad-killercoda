#!/usr/bin/env bash
set -euo pipefail

#=== Config ==============================================================
NS="manga"
NARUTO_DEP="naruto"
DEMON_DEP="demon-slayer"
EXPECTED_REPLICAS=2

#=== Helpers ============================================================
pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

need(){
  command -v "$1" >/dev/null 2>&1 || fail "Required dependency '$1' not found in PATH"
}

echo "Verifying resource configuration for deployments in namespace '$NS'..."
echo ""

#=== Preflight ==========================================================
need kubectl
need jq

# 1) Namespace
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

#========================
# Part 1: naruto deployment
#========================
echo ""
echo "Checking $NARUTO_DEP deployment..."

# 2) Deployment exists
kubectl -n "$NS" get deploy "$NARUTO_DEP" >/dev/null 2>&1 || fail "Deployment '$NARUTO_DEP' not found in '$NS'."
pass "Deployment '$NARUTO_DEP' exists"

# 3) Get deployment JSON
NARUTO_JSON="$(kubectl -n "$NS" get deploy "$NARUTO_DEP" -o json)"

# 4) Check CPU request
CPU_REQUEST=$(echo "$NARUTO_JSON" | jq -r '.spec.template.spec.containers[0].resources.requests.cpu // empty')
if [[ -z "$CPU_REQUEST" ]]; then
  fail "Deployment '$NARUTO_DEP' must have CPU requests configured"
fi
if [[ "$CPU_REQUEST" != "100m" ]]; then
  fail "Deployment '$NARUTO_DEP' CPU request should be '100m', found '$CPU_REQUEST'"
fi
pass "Deployment '$NARUTO_DEP' has correct CPU request: 100m"

# 5) Check memory request
MEM_REQUEST=$(echo "$NARUTO_JSON" | jq -r '.spec.template.spec.containers[0].resources.requests.memory // empty')
if [[ -z "$MEM_REQUEST" ]]; then
  fail "Deployment '$NARUTO_DEP' must have memory requests configured"
fi
if [[ "$MEM_REQUEST" != "100Mi" ]]; then
  fail "Deployment '$NARUTO_DEP' memory request should be '100Mi', found '$MEM_REQUEST'"
fi
pass "Deployment '$NARUTO_DEP' has correct memory request: 100Mi"

# 6) Deployment readiness
kubectl -n "$NS" rollout status "deploy/$NARUTO_DEP" --timeout=180s >/dev/null 2>&1 || fail "Deployment '$NARUTO_DEP' not ready."
READY_REPLICAS="$(kubectl -n "$NS" get deploy "$NARUTO_DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "${READY_REPLICAS:-0}" == "$EXPECTED_REPLICAS" ]] || fail "Deployment '$NARUTO_DEP' has ${READY_REPLICAS:-0} ready / needs $EXPECTED_REPLICAS."
pass "Deployment '$NARUTO_DEP' is ready with $EXPECTED_REPLICAS/$EXPECTED_REPLICAS replicas"

#========================
# Part 2: demon-slayer deployment
#========================
echo ""
echo "Checking $DEMON_DEP deployment..."

# 7) Deployment exists
kubectl -n "$NS" get deploy "$DEMON_DEP" >/dev/null 2>&1 || fail "Deployment '$DEMON_DEP' not found in '$NS'."
pass "Deployment '$DEMON_DEP' exists"

# 8) Get deployment JSON
DEMON_JSON="$(kubectl -n "$NS" get deploy "$DEMON_DEP" -o json)"

# 9) Check CPU limit
CPU_LIMIT=$(echo "$DEMON_JSON" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu // empty')
if [[ -z "$CPU_LIMIT" ]]; then
  fail "Deployment '$DEMON_DEP' must have CPU limits configured"
fi
if [[ "$CPU_LIMIT" != "200m" ]]; then
  fail "Deployment '$DEMON_DEP' CPU limit should be '200m', found '$CPU_LIMIT'"
fi
pass "Deployment '$DEMON_DEP' has correct CPU limit: 200m"

# 10) Check memory limit
MEM_LIMIT=$(echo "$DEMON_JSON" | jq -r '.spec.template.spec.containers[0].resources.limits.memory // empty')
if [[ -z "$MEM_LIMIT" ]]; then
  fail "Deployment '$DEMON_DEP' must have memory limits configured"
fi
if [[ "$MEM_LIMIT" != "200Mi" ]]; then
  fail "Deployment '$DEMON_DEP' memory limit should be '200Mi', found '$MEM_LIMIT'"
fi
pass "Deployment '$DEMON_DEP' has correct memory limit: 200Mi"

# 11) Deployment readiness
kubectl -n "$NS" rollout status "deploy/$DEMON_DEP" --timeout=180s >/dev/null 2>&1 || fail "Deployment '$DEMON_DEP' not ready."
DEMON_READY_REPLICAS="$(kubectl -n "$NS" get deploy "$DEMON_DEP" -o jsonpath='{.status.readyReplicas}')"
[[ "${DEMON_READY_REPLICAS:-0}" == "$EXPECTED_REPLICAS" ]] || fail "Deployment '$DEMON_DEP' has ${DEMON_READY_REPLICAS:-0} ready / needs $EXPECTED_REPLICAS."
pass "Deployment '$DEMON_DEP' is ready with $EXPECTED_REPLICAS/$EXPECTED_REPLICAS replicas"

#========================
# Additional checks
#========================
echo ""
echo "Additional verification..."

# 12) Verify pods are running with correct resources
NARUTO_PODS=$(kubectl -n "$NS" get pods -l app=naruto --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
[[ "$NARUTO_PODS" -ge "$EXPECTED_REPLICAS" ]] || fail "Expected at least $EXPECTED_REPLICAS running naruto pods, found $NARUTO_PODS"
pass "Found $NARUTO_PODS running naruto pods"

DEMON_PODS=$(kubectl -n "$NS" get pods -l app=demon-slayer --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
[[ "$DEMON_PODS" -ge "$EXPECTED_REPLICAS" ]] || fail "Expected at least $EXPECTED_REPLICAS running demon-slayer pods, found $DEMON_PODS"
pass "Found $DEMON_PODS running demon-slayer pods"

echo ""
echo "=========================================="
pass "All verification checks passed! Resources are correctly configured."
echo "=========================================="
echo ""
echo "Resource Summary:"
echo "  naruto deployment:"
echo "    - CPU Request: 100m"
echo "    - Memory Request: 100Mi"
echo ""
echo "  demon-slayer deployment:"
echo "    - CPU Limit: 200m"
echo "    - Memory Limit: 200Mi"
echo ""
echo "Check pod resources:"
echo "  kubectl get pods -n $NS -o custom-columns=NAME:.metadata.name,CPU-REQ:.spec.containers[0].resources.requests.cpu,CPU-LIM:.spec.containers[0].resources.limits.cpu,MEM-REQ:.spec.containers[0].resources.requests.memory,MEM-LIM:.spec.containers[0].resources.limits.memory"

#!/bin/bash
set -euo pipefail

NS="one-piece"
DEP="monkey.d.luffy"
MONITOR_DEP="crew-monitor"
SA="thousand-sunny"
MONITOR_SA="nami-navigator"
ROLE="strawhat-role"
MONITOR_ROLE="navigator-role"
ROLEBINDING="strawhat-rb"
MONITOR_RB="navigator-rb"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "Verifying RBAC configuration for deployments in namespace '$NS'..."
echo ""

# 1) Verify namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# ============================================
# Part 1: Verify monkey.d.luffy configuration
# ============================================
echo ""
echo "Checking monkey.d.luffy configuration..."

# 2) Verify Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."
pass "Deployment '$DEP' exists"

# 3) Verify ServiceAccount exists
kubectl -n "$NS" get serviceaccount "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in namespace '$NS'."
pass "ServiceAccount '$SA' exists"

# 4) Verify Role exists and has correct permissions
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in namespace '$NS'."

# Check role rules for deployments with get, list, watch
ROLE_RULES=$(kubectl -n "$NS" get role "$ROLE" -o json)

# Verify apiGroups includes "apps"
echo "$ROLE_RULES" | jq -e '.rules[] | select(.apiGroups[] == "apps")' >/dev/null 2>&1 \
  || fail "Role '$ROLE' must have apiGroups including 'apps'."

# Verify resources includes "deployments"
echo "$ROLE_RULES" | jq -e '.rules[] | select(.resources[] == "deployments")' >/dev/null 2>&1 \
  || fail "Role '$ROLE' must have resources including 'deployments'."

# Verify verbs include get, list, watch
for verb in get list watch; do
  echo "$ROLE_RULES" | jq -e ".rules[] | select(.verbs[] == \"$verb\")" >/dev/null 2>&1 \
    || fail "Role '$ROLE' must have verb '$verb'."
done

pass "Role '$ROLE' has correct permissions (get, list, watch on deployments)"

# 5) Verify RoleBinding exists and binds correctly
kubectl -n "$NS" get rolebinding "$ROLEBINDING" >/dev/null 2>&1 || fail "RoleBinding '$ROLEBINDING' not found in namespace '$NS'."

RB_ROLE=$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o jsonpath='{.roleRef.name}')
[[ "$RB_ROLE" == "$ROLE" ]] || fail "RoleBinding '$ROLEBINDING' must reference Role '$ROLE', found '$RB_ROLE'."

RB_SA=$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o jsonpath='{.subjects[0].name}')
[[ "$RB_SA" == "$SA" ]] || fail "RoleBinding '$ROLEBINDING' must bind to ServiceAccount '$SA', found '$RB_SA'."

RB_SA_NS=$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o jsonpath='{.subjects[0].namespace}')
[[ "$RB_SA_NS" == "$NS" ]] || fail "RoleBinding '$ROLEBINDING' ServiceAccount namespace must be '$NS', found '$RB_SA_NS'."

pass "RoleBinding '$ROLEBINDING' correctly binds '$ROLE' to '$SA'"

# 6) Verify Deployment uses the ServiceAccount
DEP_SA=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')
[[ "$DEP_SA" == "$SA" ]] || fail "Deployment '$DEP' must use ServiceAccount '$SA', found '${DEP_SA:-default}'."
pass "Deployment '$DEP' uses ServiceAccount '$SA'"

# 7) Verify Deployment is ready
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' is not ready."

READY_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]] || fail "Deployment '$DEP' has $READY_REPLICAS ready replicas but needs $DESIRED_REPLICAS."
pass "Deployment '$DEP' is ready with $READY_REPLICAS/$DESIRED_REPLICAS replicas"

# ============================================
# Part 2: Verify crew-monitor configuration
# ============================================
echo ""
echo "Checking crew-monitor configuration..."

# 8) Verify crew-monitor Deployment exists
kubectl -n "$NS" get deploy "$MONITOR_DEP" >/dev/null 2>&1 || fail "Deployment '$MONITOR_DEP' not found in namespace '$NS'."
pass "Deployment '$MONITOR_DEP' exists"

# 9) Verify nami-navigator ServiceAccount exists (should be pre-created)
kubectl -n "$NS" get serviceaccount "$MONITOR_SA" >/dev/null 2>&1 || fail "ServiceAccount '$MONITOR_SA' not found in namespace '$NS'."
pass "ServiceAccount '$MONITOR_SA' exists"

# 10) Verify navigator-role exists and has correct permissions
kubectl -n "$NS" get role "$MONITOR_ROLE" >/dev/null 2>&1 || fail "Role '$MONITOR_ROLE' not found in namespace '$NS'."

MONITOR_ROLE_RULES=$(kubectl -n "$NS" get role "$MONITOR_ROLE" -o json)

echo "$MONITOR_ROLE_RULES" | jq -e '.rules[] | select(.apiGroups[] == "apps")' >/dev/null 2>&1 \
  || fail "Role '$MONITOR_ROLE' must have apiGroups including 'apps'."

echo "$MONITOR_ROLE_RULES" | jq -e '.rules[] | select(.resources[] == "deployments")' >/dev/null 2>&1 \
  || fail "Role '$MONITOR_ROLE' must have resources including 'deployments'."

for verb in get list watch; do
  echo "$MONITOR_ROLE_RULES" | jq -e ".rules[] | select(.verbs[] == \"$verb\")" >/dev/null 2>&1 \
    || fail "Role '$MONITOR_ROLE' must have verb '$verb'."
done

pass "Role '$MONITOR_ROLE' has correct permissions (get, list, watch on deployments)"

# 11) Verify navigator-rb RoleBinding
kubectl -n "$NS" get rolebinding "$MONITOR_RB" >/dev/null 2>&1 || fail "RoleBinding '$MONITOR_RB' not found in namespace '$NS'."

MRB_ROLE=$(kubectl -n "$NS" get rolebinding "$MONITOR_RB" -o jsonpath='{.roleRef.name}')
[[ "$MRB_ROLE" == "$MONITOR_ROLE" ]] || fail "RoleBinding '$MONITOR_RB' must reference Role '$MONITOR_ROLE', found '$MRB_ROLE'."

MRB_SA=$(kubectl -n "$NS" get rolebinding "$MONITOR_RB" -o jsonpath='{.subjects[0].name}')
[[ "$MRB_SA" == "$MONITOR_SA" ]] || fail "RoleBinding '$MONITOR_RB' must bind to ServiceAccount '$MONITOR_SA', found '$MRB_SA'."

pass "RoleBinding '$MONITOR_RB' correctly binds '$MONITOR_ROLE' to '$MONITOR_SA'"

# 12) Verify crew-monitor uses correct ServiceAccount
MONITOR_DEP_SA=$(kubectl -n "$NS" get deploy "$MONITOR_DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')
[[ "$MONITOR_DEP_SA" == "$MONITOR_SA" ]] || fail "Deployment '$MONITOR_DEP' must use ServiceAccount '$MONITOR_SA', found '${MONITOR_DEP_SA:-default}'."
pass "Deployment '$MONITOR_DEP' uses ServiceAccount '$MONITOR_SA'"

# 13) Verify crew-monitor is ready
kubectl -n "$NS" rollout status "deploy/$MONITOR_DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$MONITOR_DEP' is not ready."
pass "Deployment '$MONITOR_DEP' is ready"

# ============================================
# Test RBAC permissions
# ============================================
echo ""
echo "Testing RBAC permissions..."

# Test thousand-sunny ServiceAccount
TEST_OUTPUT=$(kubectl run rbac-test-luffy --rm -i --restart=Never \
  --image=public.ecr.aws/bitnami/kubectl:latest \
  --serviceaccount="$SA" \
  -n "$NS" \
  --timeout=60s \
  -- get deployments -n "$NS" 2>&1) || fail "ServiceAccount '$SA' cannot list deployments. RBAC may be misconfigured."

echo "$TEST_OUTPUT" | grep -q "$DEP" || fail "ServiceAccount '$SA' can execute command but cannot see deployment '$DEP'."
pass "ServiceAccount '$SA' can successfully list deployments"

# Test nami-navigator ServiceAccount
TEST_OUTPUT2=$(kubectl run rbac-test-monitor --rm -i --restart=Never \
  --image=public.ecr.aws/bitnami/kubectl:latest \
  --serviceaccount="$MONITOR_SA" \
  -n "$NS" \
  --timeout=60s \
  -- get deployments -n "$NS" 2>&1) || fail "ServiceAccount '$MONITOR_SA' cannot list deployments. RBAC may be misconfigured."

echo "$TEST_OUTPUT2" | grep -q "$MONITOR_DEP" || fail "ServiceAccount '$MONITOR_SA' can execute command but cannot see deployment '$MONITOR_DEP'."
pass "ServiceAccount '$MONITOR_SA' can successfully list deployments"

echo ""
echo "=========================================="
pass "All verification checks passed! RBAC is correctly configured for both deployments."
echo "=========================================="
echo ""
echo "Check the deployment logs to see SUCCESS messages:"
echo "  kubectl logs deployment/$DEP -n $NS --tail=10"
echo "  kubectl logs deployment/$MONITOR_DEP -n $NS --tail=10"

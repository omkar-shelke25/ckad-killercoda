#!/usr/bin/env bash
set -euo pipefail

#=== Config ==============================================================
NS="one-piece"
DEP="monkey-d-luffy"
MONITOR_DEP="crew-monitor"
SA="thousand-sunny"
MONITOR_SA="nami-navigator"
ROLE="strawhat-role"
MONITOR_ROLE="navigator-role"
ROLEBINDING="strawhat-rb"
MONITOR_RB="navigator-rb"

#=== Helpers ============================================================
pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

need(){
  command -v "$1" >/dev/null 2>&1 || fail "Required dependency '$1' not found in PATH"
}

jq_req(){
  # Run jq with a filter and args against stdin JSON; returns non-zero on no match
  local filt="$1"; shift
  jq -e "$filt" "$@" >/dev/null
}

echo "Verifying RBAC configuration for deployments in namespace '$NS'..."
echo ""

#=== Preflight ==========================================================
need kubectl
need jq

# 1) Namespace
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

#========================
# Part 1: monkey-d-luffy
#========================
echo ""
echo "Checking $DEP configuration..."

# 2) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
pass "Deployment '$DEP' exists"

# 3) ServiceAccount exists
kubectl -n "$NS" get serviceaccount "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists"

# 4) Role exists & has correct permissions
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."
ROLE_JSON="$(kubectl -n "$NS" get role "$ROLE" -o json)"

echo "$ROLE_JSON" | jq_req '.rules[] | select((.apiGroups // []) | index("apps"))' \
  || fail "Role '$ROLE' must include apiGroup 'apps'."
echo "$ROLE_JSON" | jq_req '.rules[] | select((.resources // []) | index("deployments"))' \
  || fail "Role '$ROLE' must include resource 'deployments'."
for v in get list watch; do
  echo "$ROLE_JSON" | jq_req ".rules[] | select((.verbs // []) | index(\"$v\"))" \
    || fail "Role '$ROLE' must include verb '$v'."
done
pass "Role '$ROLE' has get,list,watch on apps/deployments"

# 5) RoleBinding correct
kubectl -n "$NS" get rolebinding "$ROLEBINDING" >/dev/null 2>&1 || fail "RoleBinding '$ROLEBINDING' not found in '$NS'."
RB_JSON="$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o json)"

echo "$RB_JSON" | jq_req \
  '.roleRef.kind=="Role" and .roleRef.apiGroup=="rbac.authorization.k8s.io" and .roleRef.name==$role' \
  --arg role "$ROLE" \
  || fail "RoleBinding '$ROLEBINDING' must reference Role '$ROLE' (rbac.authorization.k8s.io)."

echo "$RB_JSON" | jq_req \
  '.subjects[]? | select(.kind=="ServiceAccount" and .name==$sa and ((.namespace // "")==$ns))' \
  --arg sa "$SA" --arg ns "$NS" \
  || fail "RoleBinding '$ROLEBINDING' must bind ServiceAccount '$SA' in namespace '$NS'."
pass "RoleBinding '$ROLEBINDING' correctly binds '$ROLE' to '$SA'"

# 6) Deployment uses SA
DEP_SA="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$DEP_SA" == "$SA" ]] || fail "Deployment '$DEP' must use ServiceAccount '$SA', found '${DEP_SA:-default}'."
pass "Deployment '$DEP' uses ServiceAccount '$SA'"

# 7) Deployment readiness
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=180s >/dev/null 2>&1 || fail "Deployment '$DEP' not ready."
READY_REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
DESIRED_REPLICAS="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "${READY_REPLICAS:-0}" == "${DESIRED_REPLICAS:-0}" ]] || fail "Deployment '$DEP' has ${READY_REPLICAS:-0} ready / needs ${DESIRED_REPLICAS:-0}."
pass "Deployment '$DEP' is ready with ${READY_REPLICAS:-0}/${DESIRED_REPLICAS:-0} replicas"

#========================
# Part 2: crew-monitor
#========================
echo ""
echo "Checking $MONITOR_DEP configuration..."

# 8) Deployment exists
kubectl -n "$NS" get deploy "$MONITOR_DEP" >/dev/null 2>&1 || fail "Deployment '$MONITOR_DEP' not found in '$NS'."
pass "Deployment '$MONITOR_DEP' exists"

# 9) ServiceAccount exists
kubectl -n "$NS" get serviceaccount "$MONITOR_SA" >/dev/null 2>&1 || fail "ServiceAccount '$MONITOR_SA' not found in '$NS'."
pass "ServiceAccount '$MONITOR_SA' exists"

# 10) Role has correct permissions
kubectl -n "$NS" get role "$MONITOR_ROLE" >/dev/null 2>&1 || fail "Role '$MONITOR_ROLE' not found in '$NS'."
MROLE_JSON="$(kubectl -n "$NS" get role "$MONITOR_ROLE" -o json)"
echo "$MROLE_JSON" | jq_req '.rules[] | select((.apiGroups // []) | index("apps"))' \
  || fail "Role '$MONITOR_ROLE' must include apiGroup 'apps'."
echo "$MROLE_JSON" | jq_req '.rules[] | select((.resources // []) | index("deployments"))' \
  || fail "Role '$MONITOR_ROLE' must include resource 'deployments'."
for v in get list watch; do
  echo "$MROLE_JSON" | jq_req ".rules[] | select((.verbs // []) | index(\"$v\"))" \
    || fail "Role '$MONITOR_ROLE' must include verb '$v'."
done
pass "Role '$MONITOR_ROLE' has get,list,watch on apps/deployments"

# 11) RoleBinding correct
kubectl -n "$NS" get rolebinding "$MONITOR_RB" >/dev/null 2>&1 || fail "RoleBinding '$MONITOR_RB' not found in '$NS'."
MRB_JSON="$(kubectl -n "$NS" get rolebinding "$MONITOR_RB" -o json)"
echo "$MRB_JSON" | jq_req \
  '.roleRef.kind=="Role" and .roleRef.apiGroup=="rbac.authorization.k8s.io" and .roleRef.name==$role' \
  --arg role "$MONITOR_ROLE" \
  || fail "RoleBinding '$MONITOR_RB' must reference Role '$MONITOR_ROLE' (rbac.authorization.k8s.io)."

echo "$MRB_JSON" | jq_req \
  '.subjects[]? | select(.kind=="ServiceAccount" and .name==$sa and ((.namespace // "")==$ns))' \
  --arg sa "$MONITOR_SA" --arg ns "$NS" \
  || fail "RoleBinding '$MONITOR_RB' must bind ServiceAccount '$MONITOR_SA' in namespace '$NS'."
pass "RoleBinding '$MONITOR_RB' correctly binds '$MONITOR_ROLE' to '$MONITOR_SA'"

# 12) Deployment uses SA
MONITOR_DEP_SA="$(kubectl -n "$NS" get deploy "$MONITOR_DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$MONITOR_DEP_SA" == "$MONITOR_SA" ]] || fail "Deployment '$MONITOR_DEP' must use ServiceAccount '$MONITOR_SA', found '${MONITOR_DEP_SA:-default}'."
pass "Deployment '$MONITOR_DEP' uses ServiceAccount '$MONITOR_SA'"

# 13) Deployment readiness
kubectl -n "$NS" rollout status "deploy/$MONITOR_DEP" --timeout=180s >/dev/null 2>&1 || fail "Deployment '$MONITOR_DEP' not ready."
pass "Deployment '$MONITOR_DEP' is ready"

#========================
# RBAC Effective Test (kubectl auth can-i)
#========================
echo ""
echo "Testing RBAC permissions (kubectl auth can-i)..."

# thousand-sunny should be allowed to list deployments
if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} list deployments -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$SA' is NOT allowed to list deployments in '$NS'. Check Role/RoleBinding."
fi
pass "ServiceAccount '$SA' CAN list deployments in '$NS'"

# nami-navigator should be allowed to list deployments
if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${MONITOR_SA} list deployments -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$MONITOR_SA' is NOT allowed to list deployments in '$NS'. Check Role/RoleBinding."
fi
pass "ServiceAccount '$MONITOR_SA' CAN list deployments in '$NS'"

echo ""
echo "=========================================="
pass "All verification checks passed! RBAC is correctly configured for both deployments."
echo "=========================================="
echo ""
echo "Check recent logs if needed:"
echo "  kubectl logs deployment/$DEP -n $NS --tail=10"
echo "  kubectl logs deployment/$MONITOR_DEP -n $NS --tail=10"

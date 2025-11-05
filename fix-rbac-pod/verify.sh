#!/usr/bin/env bash
set -euo pipefail

#=== Config ==============================================================
NS="qa-tools"
DEP="pod-explorer"
SA="sa-explorer"
CORRECT_ROLE="pod-reader"
ROLEBINDING="explorer-rolebinding"

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

echo "Verifying RBAC configuration for pod-explorer deployment..."
echo ""

#=== Preflight ==========================================================
need kubectl
need jq

# 1) Namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 2) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
pass "Deployment '$DEP' exists"

# 3) ServiceAccount exists
kubectl -n "$NS" get serviceaccount "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists"

# 4) Deployment uses correct ServiceAccount
DEP_SA="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$DEP_SA" == "$SA" ]] || fail "Deployment '$DEP' must use ServiceAccount '$SA', found '${DEP_SA:-default}'."
pass "Deployment '$DEP' uses ServiceAccount '$SA'"

# 5) Correct Role exists (pod-reader)
kubectl -n "$NS" get role "$CORRECT_ROLE" >/dev/null 2>&1 || fail "Role '$CORRECT_ROLE' not found in '$NS'."
pass "Role '$CORRECT_ROLE' exists"

# 6) Role has correct permissions for pods
ROLE_JSON="$(kubectl -n "$NS" get role "$CORRECT_ROLE" -o json)"

# Check for core API group (empty string or "")
echo "$ROLE_JSON" | jq_req '.rules[] | select((.apiGroups // []) | map(. == "") | any)' \
  || fail "Role '$CORRECT_ROLE' must include core API group (empty string \"\")."

# Check for pods resource
echo "$ROLE_JSON" | jq_req '.rules[] | select((.resources // []) | index("pods"))' \
  || fail "Role '$CORRECT_ROLE' must include resource 'pods'."

# Check for required verbs
for v in get list watch; do
  echo "$ROLE_JSON" | jq_req ".rules[] | select((.verbs // []) | index(\"$v\"))" \
    || fail "Role '$CORRECT_ROLE' must include verb '$v'."
done
pass "Role '$CORRECT_ROLE' has correct permissions (get, list, watch on pods)"

# 7) RoleBinding exists
kubectl -n "$NS" get rolebinding "$ROLEBINDING" >/dev/null 2>&1 || fail "RoleBinding '$ROLEBINDING' not found in '$NS'."
pass "RoleBinding '$ROLEBINDING' exists"

# 8) RoleBinding references correct Role
RB_JSON="$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o json)"

echo "$RB_JSON" | jq_req \
  '.roleRef.kind=="Role" and .roleRef.apiGroup=="rbac.authorization.k8s.io" and .roleRef.name==$role' \
  --arg role "$CORRECT_ROLE" \
  || fail "RoleBinding '$ROLEBINDING' must reference Role '$CORRECT_ROLE' (rbac.authorization.k8s.io)."
pass "RoleBinding '$ROLEBINDING' references correct Role '$CORRECT_ROLE'"

# 9) RoleBinding binds to correct ServiceAccount
echo "$RB_JSON" | jq_req \
  '.subjects[]? | select(.kind=="ServiceAccount" and .name==$sa and ((.namespace // "")==$ns))' \
  --arg sa "$SA" --arg ns "$NS" \
  || fail "RoleBinding '$ROLEBINDING' must bind ServiceAccount '$SA' in namespace '$NS'."
pass "RoleBinding '$ROLEBINDING' correctly binds to ServiceAccount '$SA'"

# 10) Deployment is ready
kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=120s >/dev/null 2>&1 || fail "Deployment '$DEP' not ready."
pass "Deployment '$DEP' is ready"

# 11) RBAC Effective Test - ServiceAccount should be able to list pods
echo ""
echo "Testing RBAC permissions (kubectl auth can-i)..."

if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} list pods -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$SA' is NOT allowed to list pods in '$NS'. Check Role/RoleBinding."
fi
pass "ServiceAccount '$SA' CAN list pods in '$NS'"

if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} get pods -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$SA' is NOT allowed to get pods in '$NS'. Check Role/RoleBinding."
fi
pass "ServiceAccount '$SA' CAN get pods in '$NS'"

if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} watch pods -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$SA' is NOT allowed to watch pods in '$NS'. Check Role/RoleBinding."
fi
pass "ServiceAccount '$SA' CAN watch pods in '$NS'"

# 12) Verify the ServiceAccount CANNOT do things it shouldn't (negative tests)
echo ""
echo "Testing negative permissions (ensuring least privilege)..."

if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} delete pods -n "$NS")" == "yes" ]]; then
  fail "ServiceAccount '$SA' should NOT be able to delete pods (too many permissions)."
fi
pass "ServiceAccount '$SA' correctly CANNOT delete pods (least privilege maintained)"

if [[ "$(kubectl auth can-i --as=system:serviceaccount:${NS}:${SA} create pods -n "$NS")" == "yes" ]]; then
  fail "ServiceAccount '$SA' should NOT be able to create pods (too many permissions)."
fi
pass "ServiceAccount '$SA' correctly CANNOT create pods (least privilege maintained)"

# 13) Check deployment logs contain success messages
echo ""
echo "Checking deployment logs for success indicators..."

# Wait a bit for new logs to appear after RBAC fix
sleep 10

RECENT_LOGS="$(kubectl logs -n "$NS" deployment/"$DEP" --tail=50 2>/dev/null || echo '')"

if echo "$RECENT_LOGS" | grep -q "SUCCESS"; then
  pass "Deployment logs show successful pod listing"
elif echo "$RECENT_LOGS" | grep -q "Forbidden"; then
  fail "Deployment logs still show 'Forbidden' errors. RBAC may not be working correctly."
else
  # Logs might not have cycled yet, check permissions are correct at least
  pass "RBAC permissions verified (logs may take time to update)"
fi

echo ""
echo "=========================================="
pass "All verification checks passed! RBAC is correctly configured."
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ RoleBinding '$ROLEBINDING' created"
echo "  ✓ Bound to ServiceAccount '$SA'"
echo "  ✓ References Role '$CORRECT_ROLE'"
echo "  ✓ ServiceAccount can list, get, and watch pods"
echo "  ✓ ServiceAccount cannot delete or create pods (least privilege)"
echo ""
echo "Check deployment logs to see it working:"
echo "  kubectl logs deployment/$DEP -n $NS --tail=20 -f"

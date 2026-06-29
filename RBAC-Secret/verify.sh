#!/bin/bash
set -uo pipefail

NS="finance"
SA="specific-secret-reader-sa"
ROLE="single-secret-getter-role"
RB="single-secret-getter-binding"
SECRET="api-key-v2"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found in PATH."

echo "========================================="
echo "Verifying RBAC setup in namespace '$NS'..."
echo "========================================="

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 \
  || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 2) Secret exists
kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1 \
  || fail "Secret '$SECRET' not found in '$NS'. Create it: kubectl create secret generic $SECRET --from-literal=key=something -n $NS"
pass "Secret '$SECRET' exists"

# 3) ServiceAccount exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 \
  || fail "ServiceAccount '$SA' not found in '$NS'. Create it: kubectl create sa $SA -n $NS"
pass "ServiceAccount '$SA' exists"

# 4) Role exists with correct rule:
#    - apiGroup: "" (core)
#    - resource: secrets
#    - verb: get
#    - resourceNames: ["api-key-v2"]
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 \
  || fail "Role '$ROLE' not found in '$NS'."

RULE_OK=$(kubectl -n "$NS" get role "$ROLE" -o json | jq -r --arg s "$SECRET" '
  .rules[]?
  | select(((.apiGroups // []) | index(""))     != null)
  | select(((.resources  // []) | index("secrets")) != null)
  | select(((.verbs      // []) | index("get"))  != null)
  | select(((.resourceNames // []) | index($s)) != null)
  | "ok"
' | head -n1)

[[ "$RULE_OK" == "ok" ]] \
  || fail "Role '$ROLE' must allow verb 'get' on core resource 'secrets' restricted to resourceNames=['$SECRET']. Check your Role rules."
pass "Role '$ROLE' has correct rule (get on secrets/$SECRET only)"

# 5) RoleBinding exists and references the correct Role
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 \
  || fail "RoleBinding '$RB' not found in '$NS'."

ROLE_REF_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
ROLE_REF_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
[[ "$ROLE_REF_KIND" == "Role" && "$ROLE_REF_NAME" == "$ROLE" ]] \
  || fail "RoleBinding '$RB' must reference Role '$ROLE' (found: kind=$ROLE_REF_KIND name=$ROLE_REF_NAME)."
pass "RoleBinding '$RB' references Role '$ROLE'"

# 6) RoleBinding binds the correct ServiceAccount
SUB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUB_NS=$(kubectl -n "$NS"   get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')
[[ "$SUB_KIND" == "ServiceAccount" && "$SUB_NAME" == "$SA" && "$SUB_NS" == "$NS" ]] \
  || fail "RoleBinding '$RB' must bind ServiceAccount '$SA' in namespace '$NS' (found: kind=$SUB_KIND name=$SUB_NAME namespace=$SUB_NS)."
pass "RoleBinding '$RB' binds ServiceAccount '$SA'"

# 7) Effective permission checks
#    kubectl auth can-i exits 0 for both "yes" and "no" — must capture the output string.

echo ""
echo "── Effective permission tests ────────────────────"

# Should be ALLOWED: get secrets/api-key-v2
RESULT=$(kubectl auth can-i get "secrets/${SECRET}" \
  --as="system:serviceaccount:${NS}:${SA}" -n "$NS" 2>/dev/null || true)
[[ "$RESULT" == "yes" ]] \
  || fail "ServiceAccount '$SA' should be able to GET secrets/$SECRET in '$NS' — got '$RESULT'. Check your RoleBinding."
pass "SA can get secrets/$SECRET ✔"

# Should be DENIED: get a different secret
RESULT=$(kubectl auth can-i get secrets/some-other-secret \
  --as="system:serviceaccount:${NS}:${SA}" -n "$NS" 2>/dev/null || true)
[[ "$RESULT" == "no" ]] \
  || fail "ServiceAccount '$SA' should NOT be able to get secrets/some-other-secret — got '$RESULT'. resourceNames is not restricting correctly."
pass "SA cannot get secrets/some-other-secret ✔"

# Should be DENIED: broad get on all secrets (no resourceNames scope)
RESULT=$(kubectl auth can-i get secrets \
  --as="system:serviceaccount:${NS}:${SA}" -n "$NS" 2>/dev/null || true)
[[ "$RESULT" == "no" ]] \
  || fail "ServiceAccount '$SA' should NOT be able to broadly get all secrets — got '$RESULT'. Your Role is too permissive."
pass "SA cannot broadly get all secrets ✔"

echo ""
echo "========================================="
pass "All checks passed! RBAC is correctly configured."
echo "========================================="
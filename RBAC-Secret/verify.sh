

#!/bin/bash
set -euo pipefail

NS="finance"
SA="specific-secret-reader-sa"
ROLE="single-secret-getter-role"
RB="single-secret-getter-binding"
SECRET="api-key-v2"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 1) Secret exists
kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1 || fail "Secret '$SECRET' not found in '$NS'."

# 2) ServiceAccount exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# 3) Role exists and has rule: core group, secrets, verbs include get, resourceNames include api-key-v2
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."

RULE_OK=$(kubectl -n "$NS" get role "$ROLE" -o json | jq -r --arg s "$SECRET" '
  .rules[]? 
  | select(((.apiGroups // []) | index("")) != null)
  | select(((.resources // []) | index("secrets")) != null)
  | select(((.verbs // []) | index("get")) != null)
  | select(((.resourceNames // []) | index($s)) != null)
  | "ok"
' | head -n1)

[[ "$RULE_OK" == "ok" ]] || fail "Role '$ROLE' must allow get on core resource 'secrets' with resourceNames ['$SECRET']."

# 4) RoleBinding exists and binds SA to Role
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."

ROLE_REF_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
ROLE_REF_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
[[ "$ROLE_REF_KIND" == "Role" && "$ROLE_REF_NAME" == "$ROLE" ]] || \
  fail "RoleBinding '$RB' must reference Role '$ROLE'."

SUB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUB_NS=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')
[[ "$SUB_KIND" == "ServiceAccount" && "$SUB_NAME" == "$SA" && "$SUB_NS" == "$NS" ]] || \
  fail "RoleBinding '$RB' must bind ServiceAccount '$SA' in namespace '$NS'."

# 5) Auth checks using exit codes
# Should succeed
if ! kubectl auth can-i get "secrets/${SECRET}" --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '${SA}' cannot get secrets/${SECRET} in '${NS}'."
fi

# Should fail for some other secret
if kubectl auth can-i get secrets/some-other-secret --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '${SA}' should NOT be able to get secrets/some-other-secret in '${NS}'."
fi

# Should also fail for resource-wide get
if kubectl auth can-i get secrets --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '${SA}' should NOT be able to get the 'secrets' resource broadly in '${NS}'."
fi

pass "Verification successful!"

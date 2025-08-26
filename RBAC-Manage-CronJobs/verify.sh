#!/bin/bash
set -euo pipefail

NS="batch-processing"
SA="cron-manager-sa"
ROLE="cronjob-lifecycle-role"
RB="bind-cron-manager"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# SA exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# Role exists with correct verbs
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."

RULE_OK=$(kubectl -n "$NS" get role "$ROLE" -o json | jq -r '
  .rules[]? | select((.apiGroups|index("batch")!=null) and (.resources|index("cronjobs")!=null)) | (.verbs|sort|tostring)
' | sort -u | grep -F '["create","delete","get","list","patch","update","watch"]' || true)

[[ -n "$RULE_OK" ]] || fail "Role '$ROLE' must allow get,list,watch,create,update,patch,delete on cronjobs.batch."

# RoleBinding exists and binds correctly
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."

ROLE_REF=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}:{.roleRef.name}')
[[ "$ROLE_REF" == "Role:${ROLE}" ]] || fail "RoleBinding '$RB' must reference Role '$ROLE'."

SUB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUB_NS=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')

[[ "$SUB_KIND" == "ServiceAccount" && "$SUB_NAME" == "$SA" && "$SUB_NS" == "$NS" ]] || fail "RoleBinding '$RB' must bind ServiceAccount '$SA' in namespace '$NS'."

# Auth checks
kubectl auth can-i create cronjobs.batch --as="system:serviceaccount:${NS}:${SA}" -n "$NS" | grep -qi '^yes$' || fail "SA cannot create cronjobs in '${NS}'."
kubectl auth can-i create pods --as="system:serviceaccount:${NS}:${SA}" -n "$NS" | grep -qi '^no$' || fail "SA should NOT be able to create pods in '${NS}'."

pass "Verification successful!"

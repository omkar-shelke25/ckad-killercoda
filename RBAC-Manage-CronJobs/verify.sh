#!/bin/bash
set -euo pipefail

NS="batch-processing"
SA="cron-manager-sa"
ROLE="cronjob-lifecycle-role"
RB="bind-cron-manager"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 0) Prereqs
command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2) ServiceAccount exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# 3) Role exists
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."

# 4) Role rules include cronjobs in batch with all required verbs (allow extras)
REQUIRED_VERBS=(create delete get list patch update watch)

# Grab the unique verbs on rules that target cronjobs in the batch API group
mapfile -t ROLE_VERBS < <(
  kubectl -n "$NS" get role "$ROLE" -o json \
  | jq -r '.rules[]? 
      | select((.apiGroups // []) | index("batch"))
      | select((.resources // []) | index("cronjobs"))
      | .verbs[]' \
  | sort -u
)

# Build a set for quick membership checks
HAVE_VERBS=" ${ROLE_VERBS[*]} "
for v in "${REQUIRED_VERBS[@]}"; do
  if [[ "$HAVE_VERBS" != *" $v "* ]]; then
    fail "Role '$ROLE' is missing required verb '$v' on resource 'cronjobs.batch'."
  fi
done

# 5) RoleBinding exists
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."

# 6) RoleBinding references the correct Role and subject
RB_ROLE_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
RB_ROLE_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
[[ "$RB_ROLE_KIND" == "Role" && "$RB_ROLE_NAME" == "$ROLE" ]] \
  || fail "RoleBinding '$RB' must reference Role '$ROLE' (found $RB_ROLE_KIND/$RB_ROLE_NAME)."

SUB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUB_NS=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')
[[ "$SUB_KIND" == "ServiceAccount" && "$SUB_NAME" == "$SA" && "$SUB_NS" == "$NS" ]] \
  || fail "RoleBinding '$RB' must bind ServiceAccount '$SA' in namespace '$NS'."

# 7) Auth checks using exit codes (most reliable)
# Should SUCCEED: create cronjobs.batch
if ! kubectl auth can-i create cronjobs.batch --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '${SA}' cannot create cronjobs in '${NS}'."
fi

# Should FAIL: create pods
if kubectl auth can-i create pods --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '${SA}' should NOT be able to create pods in '${NS}'."
fi

pass "Verification successful!"

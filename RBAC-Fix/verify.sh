#!/bin/bash
set -euo pipefail

NS="project-alpha"
SA="dev-user-1"
ROLE="config-reader"
RB="dev-user-1-binding"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# SA exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."

# Role exists
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."

# RoleBinding exists
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."

# Role must contain plural 'configmaps'
if ! kubectl -n "$NS" get role "$ROLE" -o json | jq -e '.rules[]?.resources? | index("configmaps")' >/dev/null; then
  fail "Role '$ROLE' does not grant access to 'configmaps' (plural)."
fi
pass "Role '$ROLE' grants access to 'configmaps'."

# RoleBinding should point to the right SA and Role
RB_JSON=$(kubectl -n "$NS" get rolebinding "$RB" -o json)
RB_ROLE_REF=$(echo "$RB_JSON" | jq -r '.roleRef.name')
if [ "$RB_ROLE_REF" != "$ROLE" ]; then
  fail "RoleBinding '$RB' roleRef.name is '$RB_ROLE_REF', expected '$ROLE'."
fi
if ! echo "$RB_JSON" | jq -e --arg sa "$SA" --arg ns "$NS" '.subjects[] | select(.kind=="ServiceAccount" and .name==$sa and .namespace==$ns)' >/dev/null; then
  fail "RoleBinding '$RB' does not target ServiceAccount '$SA' in '$NS'."
fi
pass "RoleBinding '$RB' targets the correct SA and Role."

# Can the SA list configmaps now?
if ! kubectl auth can-i list configmaps --as="system:serviceaccount:${NS}:${SA}" -n "$NS" >/dev/null 2>&1; then
  fail "ServiceAccount '$SA' still cannot list configmaps in '$NS'."
fi
pass "ServiceAccount '$SA' can list configmaps."

# Optional: try to actually list (should not fail)
kubectl -n "$NS" get configmaps --as="system:serviceaccount:${NS}:${SA}" >/dev/null

pass "Verification successful! RBAC is correctly configured."

#!/bin/bash
# Verifier: RBAC — Namespaced Pod Viewer (final robust)
set -euo pipefail

NS="dev-team-1"
SA="pod-viewer-sa"
ROLE="pod-reader-role"
RB="pod-viewer-binding"
SA_FQN="system:serviceaccount:${NS}:${SA}"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

trim_can_i() {
  # run kubectl auth can-i and normalize to "yes" or "no"
  local out
  out="$( "$@" 2>/dev/null | tr -d '\r' | tr -d '[:space:]' )"
  echo "$out"
}

# 1) Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists."

# 2) ServiceAccount
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists in '$NS'."

# 3) Role presence
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."

# 3a–c) Role rules (match YAML list items directly)
ROLE_YAML="$(kubectl -n "$NS" get role "$ROLE" -o yaml)"
echo "$ROLE_YAML" | grep -qE '^\s*-\s*""\s*$'    || { echo "$ROLE_YAML"; fail 'Role must target core API group (apiGroups: [""]).'; }
echo "$ROLE_YAML" | grep -qE '^\s*-\s*pods\s*$'  || { echo "$ROLE_YAML"; fail "Role must include resource 'pods'."; }
echo "$ROLE_YAML" | grep -qE '^\s*-\s*get\s*$'   || { echo "$ROLE_YAML"; fail "Role is missing verb 'get'."; }
echo "$ROLE_YAML" | grep -qE '^\s*-\s*list\s*$'  || { echo "$ROLE_YAML"; fail "Role is missing verb 'list'."; }
echo "$ROLE_YAML" | grep -qE '^\s*-\s*watch\s*$' || { echo "$ROLE_YAML"; fail "Role is missing verb 'watch'."; }
pass "Role '$ROLE' has correct rules."

# 4) RoleBinding correctness
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."

RB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
RB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
RB_API=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.apiGroup}')

[ "$RB_KIND" = "Role" ] || fail "RoleBinding must reference kind=Role (not ClusterRole)."
[ "$RB_NAME" = "$ROLE" ] || fail "RoleBinding must reference role '$ROLE'."
[ "$RB_API"  = "rbac.authorization.k8s.io" ] || fail "roleRef.apiGroup must be rbac.authorization.k8s.io."

SUB_LINES=$(kubectl -n "$NS" get rolebinding "$RB" \
  -o jsonpath='{range .subjects[*]}{.kind}{"|"}{.name}{"|"}{.namespace}{"\n"}{end}' | tr -d '\r')
MATCH_LINE=$(awk -F'|' -v ns="$NS" -v sa="$SA" '$1=="ServiceAccount" && $2==sa && ($3==ns || $3=="") {print; exit}' <<<"$SUB_LINES")
[ -n "${MATCH_LINE:-}" ] || { echo "Debug subjects:"; nl -ba <<<"$SUB_LINES"; fail "RoleBinding must bind ServiceAccount '$SA' in namespace '$NS'."; }
pass "RoleBinding '$RB' correctly binds Role → ServiceAccount."

# 5) Effective permissions (trim output before comparing)
YES_NS=$(trim_can_i kubectl auth can-i list pods --as="$SA_FQN" -n "$NS")
[ "$YES_NS" = "yes" ] || fail "SA should be able to list pods in '$NS' (got: $YES_NS)."
pass "SA can list pods in '$NS'."

NO_DEF=$(trim_can_i kubectl auth can-i list pods --as="$SA_FQN" -n default)
[ "$NO_DEF" = "no" ] || fail "SA must NOT be able to list pods in 'default' (got: $NO_DEF)."
pass "SA cannot list pods in 'default'."

echo "🎉 All checks passed."

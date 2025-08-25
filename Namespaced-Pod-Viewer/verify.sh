#!/bin/bash
# Verifier: RBAC — Namespaced Pod Viewer
set -euo pipefail

NS="dev-team-1"
SA="pod-viewer-sa"
ROLE="pod-reader-role"
RB="pod-viewer-binding"
SA_FQN="system:serviceaccount:${NS}:${SA}"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Namespace pre-created by setup
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists."

# ServiceAccount
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists in '$NS'."

# Role correctness (resources/verbs/apiGroup)
kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS'."
ROLE_JSON=$(kubectl -n "$NS" get role "$ROLE" -o json)

echo "$ROLE_JSON" | grep -q '"resources": \["pods"\]' || fail "Role must include resource 'pods'."
echo "$ROLE_JSON" | grep -Eq '"apiGroups": \[\s*""\s*\]' || fail "Role must target core API group (apiGroups: [\"\"])."

for v in get list watch; do
  echo "$ROLE_JSON" | grep -q "\"$v\"" || fail "Role is missing verb '$v'."
done
pass "Role '$ROLE' has correct rules."

# RoleBinding correctness
kubectl -n "$NS" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS'."
RB_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
RB_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
RB_API=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.roleRef.apiGroup}')
SUBJ_KIND=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUBJ_NAME=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUBJ_NS=$(kubectl -n "$NS" get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')

[ "$RB_KIND" = "Role" ] || fail "RoleBinding must reference kind=Role (not ClusterRole)."
[ "$RB_NAME" = "$ROLE" ] || fail "RoleBinding must reference role '$ROLE'."
[ "$RB_API"  = "rbac.authorization.k8s.io" ] || fail "roleRef.apiGroup must be rbac.authorization.k8s.io."
[ "$SUBJ_KIND" = "ServiceAccount" ] || fail "Subject kind must be ServiceAccount."
[ "$SUBJ_NAME" = "$SA" ] || fail "Subject name must be '$SA'."
[ "$SUBJ_NS"   = "$NS" ] || fail "Subject namespace must be '$NS'."
pass "RoleBinding '$RB' correctly binds Role → ServiceAccount."

# Positive auth check in dev-team-1
kubectl auth can-i list pods --as="$SA_FQN" -n "$NS" | grep -qw yes || fail "SA should be able to list pods in '$NS'."
pass "SA can list pods in '$NS'."

# Negative auth check in default
kubectl auth can-i list pods --as="$SA_FQN" -n default | grep -qw no || fail "SA must NOT be able to list pods in 'default'."
pass "SA cannot list pods in 'default'."

echo "🎉 All checks passed."

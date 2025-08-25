#!/bin/bash
# Verifier: RBAC — ClusterRole Node Reader + SA attached to Deployment (aggregation-aware)
set -euo pipefail

NS="monitoring"
SA="node-inspector-sa"
CR="node-reader-crole"
CRB="node-inspector-crbinding"
DEPLOY="node-inspector-ui"
LABEL="app=node-inspector-ui"
SA_FQN="system:serviceaccount:${NS}:${SA}"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }
trim_can_i(){ "$@" 2>/dev/null | tr -d '\r' | tr -d '[:space:]'; }

# 1) Namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists."

# 2) ServiceAccount
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists in '$NS'."

# 3) ClusterRole exists
kubectl get clusterrole "$CR" >/dev/null 2>&1 || fail "ClusterRole '$CR' not found."

CR_YAML="$(kubectl get clusterrole "$CR" -o yaml)"
HAS_RULES=$(echo "$CR_YAML" | awk '/^rules:/ {print "yes"; exit}')
HAS_AGG=$(echo "$CR_YAML"   | awk '/^aggregationRule:/ {print "yes"; exit}')

if [ "${HAS_RULES:-}" = "yes" ]; then
  # Static rule checks (explicit rules present)
  echo "$CR_YAML" | grep -qE '^\s*-\s*""\s*$'    || { echo "$CR_YAML"; fail 'ClusterRole must target core API group (apiGroups: [""]).'; }
  echo "$CR_YAML" | grep -qE '^\s*-\s*nodes\s*$' || { echo "$CR_YAML"; fail "ClusterRole must include resource 'nodes'."; }
  echo "$CR_YAML" | grep -qE '^\s*-\s*get\s*$'   || { echo "$CR_YAML"; fail "ClusterRole is missing verb 'get'."; }
  echo "$CR_YAML" | grep -qE '^\s*-\s*list\s*$'  || { echo "$CR_YAML"; fail "ClusterRole is missing verb 'list'."; }
  pass "ClusterRole '$CR' has correct explicit rules (core group, resource nodes, verbs get,list)."
elif [ "${HAS_AGG:-}" = "yes" ]; then
  echo "ℹ️ ClusterRole '$CR' uses aggregationRule; skipping static rule checks and validating via effective permissions."
else
  echo "$CR_YAML"
  fail "ClusterRole '$CR' has no explicit rules and no aggregationRule."
fi

# 4) ClusterRoleBinding correctness (don’t assume subjects[0])
kubectl get clusterrolebinding "$CRB" >/dev/null 2>&1 || fail "ClusterRoleBinding '$CRB' not found."
CRB_KIND=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.kind}')
CRB_NAME=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.name}')
CRB_API=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.apiGroup}')
[ "$CRB_KIND" = "ClusterRole" ] || fail "Binding must reference kind=ClusterRole."
[ "$CRB_NAME" = "$CR" ] || fail "Binding must reference ClusterRole '$CR'."
[ "$CRB_API"  = "rbac.authorization.k8s.io" ] || fail "roleRef.apiGroup must be rbac.authorization.k8s.io."

SUB_LINES=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{range .subjects[*]}{.kind}{"|"}{.name}{"|"}{.namespace}{"\n"}{end}' | tr -d '\r')
MATCH_LINE=$(awk -F'|' -v ns="$NS" -v sa="$SA" '$1=="ServiceAccount" && $2==sa && ($3==ns || $3=="") {print; exit}' <<<"$SUB_LINES")
[ -n "${MATCH_LINE:-}" ] || { echo "Debug subjects:"; nl -ba <<<"$SUB_LINES"; fail "ClusterRoleBinding must bind ServiceAccount '$SA' in namespace '$NS'."; }
pass "ClusterRoleBinding '$CRB' correctly binds ClusterRole → ServiceAccount."

# 5) Deployment uses the SA
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in '$NS'."
DEPLOY_SA=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.serviceAccountName}')
[ "$DEPLOY_SA" = "$SA" ] || fail "Deployment '$DEPLOY' must use serviceAccountName='$SA' (found '$DEPLOY_SA')."
pass "Deployment '$DEPLOY' uses serviceAccountName='$SA'."

# 6) Pod (best-effort)
POD_NAME=$(kubectl -n "$NS" get pods -l "$LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "${POD_NAME:-}" ]; then
  POD_SA=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.spec.serviceAccountName}')
  [ "$POD_SA" = "$SA" ] || fail "Pod '$POD_NAME' should run with SA '$SA' (found '$POD_SA')."
  pass "Pod '$POD_NAME' is running with serviceAccountName='$SA'."
else
  echo "ℹ️ No Pods found for label '$LABEL'; continuing based on Deployment template."
fi

# 7) Effective permissions (the ground truth for nodes)
[ "$(trim_can_i kubectl auth can-i get   nodes --as="$SA_FQN")" = "yes" ] || fail "SA should be able to get nodes cluster-wide."
[ "$(trim_can_i kubectl auth can-i list  nodes --as="$SA_FQN")" = "yes" ] || fail "SA should be able to list nodes cluster-wide."
[ "$(trim_can_i kubectl auth can-i delete nodes --as="$SA_FQN")" = "no"  ] || fail "SA must NOT be able to delete nodes."
pass "SA can get/list nodes, and cannot delete nodes (as expected)."

echo "🎉 All checks passed."

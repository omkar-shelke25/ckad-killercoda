#!/bin/bash
# Verifier: RBAC — ClusterRole Node Reader + SA attached to Deployment
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

# 1) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists."

# 2) ServiceAccount exists
kubectl -n "$NS" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS'."
pass "ServiceAccount '$SA' exists in '$NS'."

# 3) ClusterRole correctness
kubectl get clusterrole "$CR" >/dev/null 2>&1 || fail "ClusterRole '$CR' not found."
CR_JSON=$(kubectl get clusterrole "$CR" -o json)
echo "$CR_JSON" | grep -q '"resources": \["nodes"\]' || fail "ClusterRole must include resource 'nodes'."
echo "$CR_JSON" | grep -Eq '"apiGroups": \[\s*""\s*\]' || fail "ClusterRole must target core API group (apiGroups: [\"\"])."
for v in get list; do
  echo "$CR_JSON" | grep -q "\"$v\"" || fail "ClusterRole is missing verb '$v'."
done
pass "ClusterRole '$CR' has correct rules (nodes: get,list in core API group)."

# 4) ClusterRoleBinding correctness (roleRef + subject)
kubectl get clusterrolebinding "$CRB" >/dev/null 2>&1 || fail "ClusterRoleBinding '$CRB' not found."
CRB_KIND=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.kind}')
CRB_NAME=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.name}')
CRB_API=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.roleRef.apiGroup}')
SUBJ_KIND=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.subjects[0].kind}')
SUBJ_NAME=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.subjects[0].name}')
SUBJ_NS=$(kubectl get clusterrolebinding "$CRB" -o jsonpath='{.subjects[0].namespace}')
[ "$CRB_KIND" = "ClusterRole" ] || fail "Binding must reference kind=ClusterRole."
[ "$CRB_NAME" = "$CR" ] || fail "Binding must reference ClusterRole '$CR'."
[ "$CRB_API"  = "rbac.authorization.k8s.io" ] || fail "roleRef.apiGroup must be rbac.authorization.k8s.io."
[ "$SUBJ_KIND" = "ServiceAccount" ] || fail "Subject kind must be ServiceAccount."
[ "$SUBJ_NAME" = "$SA" ] || fail "Subject name must be '$SA'."
[ "$SUBJ_NS"   = "$NS" ] || fail "Subject namespace must be '$NS'."
pass "ClusterRoleBinding '$CRB' correctly binds ClusterRole → ServiceAccount."

# 5) Deployment exists and uses the ServiceAccount
kubectl -n "$NS" get deploy "$DEPLOY" >/dev/null 2>&1 || fail "Deployment '$DEPLOY' not found in '$NS'."
DEPLOY_SA=$(kubectl -n "$NS" get deploy "$DEPLOY" -o jsonpath='{.spec.template.spec.serviceAccountName}')
[ "$DEPLOY_SA" = "$SA" ] || fail "Deployment '$DEPLOY' must use serviceAccountName='$SA' (found '$DEPLOY_SA')."
pass "Deployment '$DEPLOY' uses serviceAccountName='$SA'."

# 6) Ensure a Pod from the Deployment is running with the SA (best-effort check)
POD_NAME=$(kubectl -n "$NS" get pods -l "$LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "${POD_NAME:-}" ]; then
  POD_SA=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.spec.serviceAccountName}')
  [ "$POD_SA" = "$SA" ] || fail "Pod '$POD_NAME' should run with SA '$SA' (found '$POD_SA'). Did you patch the deployment and let it roll out?"
  pass "Pod '$POD_NAME' is running with serviceAccountName='$SA'."
else
  echo "ℹ️ No Pods found for label '$LABEL'; continuing based on Deployment template."
fi

# 7) Positive auth checks (cluster-scoped; no -n flag)
kubectl auth can-i get nodes  --as="$SA_FQN" | grep -qw yes || fail "SA should be able to get nodes cluster-wide."
kubectl auth can-i list nodes --as="$SA_FQN" | grep -qw yes || fail "SA should be able to list nodes cluster-wide."
pass "SA can get/list nodes cluster-wide."

# 8) Negative auth check (must not delete nodes)
kubectl auth can-i delete nodes --as="$SA_FQN" | grep -qw no || fail "SA must NOT be able to delete nodes."
pass "SA cannot delete nodes (as expected)."

echo "🎉 All checks passed."

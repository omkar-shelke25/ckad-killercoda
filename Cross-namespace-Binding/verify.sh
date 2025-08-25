#!/bin/bash
# Verifier: RBAC — Only pods/log access from default SA into app-prod
set -euo pipefail

NS_TARGET="app-prod"
NS_SA="default"
SA="log-scraper-sa"
ROLE="log-reader-role"
RB="log-scraper-binding"
SA_FQN="system:serviceaccount:${NS_SA}:${SA}"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) Namespaces present
kubectl get ns "$NS_TARGET" >/dev/null 2>&1 || fail "Namespace '$NS_TARGET' not found."
kubectl get ns "$NS_SA" >/dev/null 2>&1 || fail "Namespace '$NS_SA' not found."
pass "Namespaces '$NS_TARGET' and '$NS_SA' exist."

# 2) ServiceAccount exists in default
kubectl -n "$NS_SA" get sa "$SA" >/dev/null 2>&1 || fail "ServiceAccount '$SA' not found in '$NS_SA'."
pass "ServiceAccount '$SA' exists in '$NS_SA'."

# 3) Role exists in app-prod with exact minimal scope: pods/log + get only + core API group
kubectl -n "$NS_TARGET" get role "$ROLE" >/dev/null 2>&1 || fail "Role '$ROLE' not found in '$NS_TARGET'."

RES_LIST=$(kubectl -n "$NS_TARGET" get role "$ROLE" -o jsonpath='{range .rules[*]}{.resources}{" "}{end}')
VERB_LIST=$(kubectl -n "$NS_TARGET" get role "$ROLE" -o jsonpath='{range .rules[*]}{.verbs}{" "}{end}')
APIG_LIST=$(kubectl -n "$NS_TARGET" get role "$ROLE" -o jsonpath='{range .rules[*]}{.apiGroups}{" "}{end}')

echo "$RES_LIST" | grep -qw "pods/log" || fail "Role '$ROLE' must include resource 'pods/log'."
echo "$RES_LIST" | grep -qw "pods" && fail "Role '$ROLE' must NOT include resource 'pods' (without /log)."

# Ensure only 'get' verb is present (no list/watch/create/update/patch/delete/exec/attach)
echo "$VERB_LIST" | grep -qw get || fail "Role '$ROLE' must include verb 'get'."
for bad in list watch create update patch delete deletecollection exec attach proxy redirect; do
  echo "$VERB_LIST" | grep -qw "$bad" && fail "Role '$ROLE' must NOT include verb '$bad'."
done

# API group core (accept [] or [""])
echo "$APIG_LIST" | grep -Eq '(\[\]|\[""\])' || fail "Role '$ROLE' must target core API group (apiGroups: [\"\"] or [])."
pass "Role '$ROLE' correctly grants only 'get' on 'pods/log' in core API group."

# 4) RoleBinding correctness in app-prod (binds Role -> SA in default)
kubectl -n "$NS_TARGET" get rolebinding "$RB" >/dev/null 2>&1 || fail "RoleBinding '$RB' not found in '$NS_TARGET'."

RB_KIND=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.roleRef.kind}')
RB_NAME=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.roleRef.name}')
RB_API=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.roleRef.apiGroup}')
SUBJ_KIND=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.subjects[0].kind}')
SUBJ_NAME=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.subjects[0].name}')
SUBJ_NS=$(kubectl -n "$NS_TARGET" get rolebinding "$RB" -o jsonpath='{.subjects[0].namespace}')

[ "$RB_KIND" = "Role" ] || fail "RoleBinding '$RB' must reference kind=Role."
[ "$RB_NAME" = "$ROLE" ] || fail "RoleBinding '$RB' must reference role '$ROLE'."
[ "$RB_API"  = "rbac.authorization.k8s.io" ] || fail "roleRef.apiGroup must be rbac.authorization.k8s.io."
[ "$SUBJ_KIND" = "ServiceAccount" ] || fail "Subject kind must be ServiceAccount."
[ "$SUBJ_NAME" = "$SA" ] || fail "Subject name must be '$SA'."
[ "$SUBJ_NS"   = "$NS_SA" ] || fail "Subject namespace must be '$NS_SA'."
pass "RoleBinding '$RB' binds Role → ServiceAccount 'default/$SA' correctly."

# 5) Permission checks (impersonation). Ignore warnings; retry to avoid propagation races.

retry_can_i () {
  local expect="$1" ; shift
  local cmd=(kubectl auth can-i "$@" --as="$SA_FQN")
  for i in 1 2 3; do
    if "${cmd[@]}" 2>/dev/null | grep -qw "$expect"; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# Positive: get pods/log in app-prod
retry_can_i yes -n "$NS_TARGET" get pods --subresource=log \
  || fail "SA should be able to 'get' pods/log in '$NS_TARGET'."
pass "SA can 'get' pods/log in '$NS_TARGET'."

# Negative: cannot get pods (no subresource) in app-prod
retry_can_i no -n "$NS_TARGET" get pods \
  || fail "SA must NOT be able to 'get' pods (without subresource) in '$NS_TARGET'."
pass "SA cannot 'get' pods (no subresource) in '$NS_TARGET'."

# Negative: cannot list pods/log in app-prod
retry_can_i no -n "$NS_TARGET" list pods --subresource=log \
  || fail "SA must NOT be able to 'list' pods/log in '$NS_TARGET'."
pass "SA cannot 'list' pods/log in '$NS_TARGET'."

# Negative: cannot get pods/log in default
retry_can_i no -n default get pods --subresource=log \
  || fail "SA must NOT be able to 'get' pods/log in 'default'."
pass "SA cannot 'get' pods/log in 'default'."

echo "🎉 All checks passed."

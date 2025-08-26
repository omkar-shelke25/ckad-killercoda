#!/bin/bash
set -euo pipefail

CR="storage-viewer-crole"
CRB="sara-storage-viewer-crbinding"
USER="sara.jones@example.com"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# 1) ClusterRole exists
kubectl get clusterrole "${CR}" >/dev/null 2>&1 || fail "ClusterRole '${CR}' not found."

# 2) ClusterRole rules: PVCs in core group with get,list,watch
PVC_RULE_OK=$(kubectl get clusterrole "${CR}" -o json | jq -r '
  .rules[]? | select(((.apiGroups // []) | index("") != null) and ((.resources // []) | index("persistentvolumeclaims") != null)) | 
  (.verbs|sort|tostring)
' | sort -u | grep -F '["get","list","watch"]' || true)
[[ -n "${PVC_RULE_OK}" ]] || fail "ClusterRole '${CR}' must allow verbs get,list,watch on 'persistentvolumeclaims' in apiGroup '' (core)."

# 3) ClusterRole rules: StorageClasses in storage.k8s.io with get,list,watch
SC_RULE_OK=$(kubectl get clusterrole "${CR}" -o json | jq -r '
  .rules[]? | select(((.apiGroups // []) | index("storage.k8s.io") != null) and ((.resources // []) | index("storageclasses") != null)) | 
  (.verbs|sort|tostring)
' | sort -u | grep -F '["get","list","watch"]' || true)
[[ -n "${SC_RULE_OK}" ]] || fail "ClusterRole '${CR}' must allow verbs get,list,watch on 'storageclasses' in apiGroup 'storage.k8s.io'."

# 4) ClusterRoleBinding exists and points to the role
kubectl get clusterrolebinding "${CRB}" >/dev/null 2>&1 || fail "ClusterRoleBinding '${CRB}' not found."
ROLE_REF_OK=$(kubectl get clusterrolebinding "${CRB}" -o jsonpath='{.roleRef.kind}:{.roleRef.name}')
[[ "${ROLE_REF_OK}" == "ClusterRole:${CR}" ]] || fail "ClusterRoleBinding '${CRB}' must reference ClusterRole '${CR}'."

# 5) Subject is a User with the right name
SUBJECT_KIND=$(kubectl get clusterrolebinding "${CRB}" -o jsonpath='{.subjects[0].kind}')
SUBJECT_NAME=$(kubectl get clusterrolebinding "${CRB}" -o jsonpath='{.subjects[0].name}')
SUBJECT_API_GROUP=$(kubectl get clusterrolebinding "${CRB}" -o jsonpath='{.subjects[0].apiGroup}')
[[ "${SUBJECT_KIND}" == "User" && "${SUBJECT_NAME}" == "${USER}" && "${SUBJECT_API_GROUP}" == "rbac.authorization.k8s.io" ]] || \
  fail "ClusterRoleBinding '${CRB}' must bind kind=User, name='${USER}', apiGroup=rbac.authorization.k8s.io."

# 6) Auth checks as the user
kubectl auth can-i list persistentvolumeclaims --as="${USER}" --all-namespaces | grep -qi '^yes$' || \
  fail "User ${USER} cannot list PVCs cluster-wide."
kubectl auth can-i list storageclasses --as="${USER}" | grep -qi '^yes$' || \
  fail "User ${USER} cannot list StorageClasses."

pass "Verification successful!"

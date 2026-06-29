#!/usr/bin/env bash
set -euo pipefail

#=== Config ================================================================
NS="one-piece"
DEP="monkey-d-luffy"
MONITOR_DEP="crew-monitor"
SA="thousand-sunny"
MONITOR_SA="nami-navigator"
ROLE="strawhat-role"
MONITOR_ROLE="navigator-role"
ROLEBINDING="strawhat-rb"
MONITOR_RB="navigator-rb"

#=== Helpers ===============================================================
pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Required tool '$1' not found in PATH"; }
jq_match() { jq -e "$1" "${@:2}" >/dev/null; }

echo "==========================================="
echo "Verifying RBAC setup in namespace '$NS'..."
echo "==========================================="

need kubectl
need jq

# Namespace
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# ===========================================================================
echo ""
echo "── Part 1: $DEP ──────────────────────────────"

kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 \
  || fail "Deployment '$DEP' not found in namespace '$NS'."
pass "Deployment '$DEP' exists"

kubectl -n "$NS" get serviceaccount "$SA" >/dev/null 2>&1 \
  || fail "ServiceAccount '$SA' not found. Did you run: kubectl create serviceaccount $SA -n $NS ?"
pass "ServiceAccount '$SA' exists"

kubectl -n "$NS" get role "$ROLE" >/dev/null 2>&1 \
  || fail "Role '$ROLE' not found. Create it with the correct verbs on apps/deployments."
ROLE_JSON="$(kubectl -n "$NS" get role "$ROLE" -o json)"

jq_match '.rules[] | select((.apiGroups // []) | index("apps"))' <<< "$ROLE_JSON" \
  || fail "Role '$ROLE' is missing apiGroup 'apps'. Deployments live under the apps API group."
jq_match '.rules[] | select((.resources // []) | index("deployments"))' <<< "$ROLE_JSON" \
  || fail "Role '$ROLE' is missing resource 'deployments'."
for verb in get list watch; do
  jq_match ".rules[] | select((.verbs // []) | index(\"$verb\"))" <<< "$ROLE_JSON" \
    || fail "Role '$ROLE' is missing verb '$verb'."
done
pass "Role '$ROLE' grants get, list, watch on apps/deployments"

kubectl -n "$NS" get rolebinding "$ROLEBINDING" >/dev/null 2>&1 \
  || fail "RoleBinding '$ROLEBINDING' not found."
RB_JSON="$(kubectl -n "$NS" get rolebinding "$ROLEBINDING" -o json)"

jq_match \
  '.roleRef | .kind=="Role" and .apiGroup=="rbac.authorization.k8s.io" and .name==$r' \
  --arg r "$ROLE" <<< "$RB_JSON" \
  || fail "RoleBinding '$ROLEBINDING' must reference Role '$ROLE' (kind: Role, apiGroup: rbac.authorization.k8s.io)."

jq_match \
  '.subjects[]? | select(.kind=="ServiceAccount" and .name==$sa and .namespace==$ns)' \
  --arg sa "$SA" --arg ns "$NS" <<< "$RB_JSON" \
  || fail "RoleBinding '$ROLEBINDING' must bind ServiceAccount '$SA' in namespace '$NS'."
pass "RoleBinding '$ROLEBINDING' binds '$ROLE' → '$SA'"

DEP_SA="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$DEP_SA" == "$SA" ]] \
  || fail "Deployment '$DEP' still uses ServiceAccount '${DEP_SA:-default}'. Run: kubectl set serviceaccount deployment $DEP $SA -n $NS"
pass "Deployment '$DEP' uses ServiceAccount '$SA'"

kubectl -n "$NS" rollout status "deploy/$DEP" --timeout=180s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' is not ready (pods may be crashing)."
READY="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')"
DESIRED="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')"
[[ "${READY:-0}" == "${DESIRED:-0}" ]] \
  || fail "Deployment '$DEP': ${READY:-0}/${DESIRED:-0} replicas ready."
pass "Deployment '$DEP' is ready (${READY}/${DESIRED} replicas)"

# ===========================================================================
echo ""
echo "── Part 2: $MONITOR_DEP ────────────────────────────"

kubectl -n "$NS" get deploy "$MONITOR_DEP" >/dev/null 2>&1 \
  || fail "Deployment '$MONITOR_DEP' not found in namespace '$NS'."
pass "Deployment '$MONITOR_DEP' exists"

kubectl -n "$NS" get serviceaccount "$MONITOR_SA" >/dev/null 2>&1 \
  || fail "ServiceAccount '$MONITOR_SA' not found."
pass "ServiceAccount '$MONITOR_SA' exists"

kubectl -n "$NS" get role "$MONITOR_ROLE" >/dev/null 2>&1 \
  || fail "Role '$MONITOR_ROLE' not found."
MROLE_JSON="$(kubectl -n "$NS" get role "$MONITOR_ROLE" -o json)"

jq_match '.rules[] | select((.apiGroups // []) | index("apps"))' <<< "$MROLE_JSON" \
  || fail "Role '$MONITOR_ROLE' is missing apiGroup 'apps'."
jq_match '.rules[] | select((.resources // []) | index("deployments"))' <<< "$MROLE_JSON" \
  || fail "Role '$MONITOR_ROLE' is missing resource 'deployments'."
for verb in get list watch; do
  jq_match ".rules[] | select((.verbs // []) | index(\"$verb\"))" <<< "$MROLE_JSON" \
    || fail "Role '$MONITOR_ROLE' is missing verb '$verb'."
done
pass "Role '$MONITOR_ROLE' grants get, list, watch on apps/deployments"

kubectl -n "$NS" get rolebinding "$MONITOR_RB" >/dev/null 2>&1 \
  || fail "RoleBinding '$MONITOR_RB' not found."
MRB_JSON="$(kubectl -n "$NS" get rolebinding "$MONITOR_RB" -o json)"

jq_match \
  '.roleRef | .kind=="Role" and .apiGroup=="rbac.authorization.k8s.io" and .name==$r' \
  --arg r "$MONITOR_ROLE" <<< "$MRB_JSON" \
  || fail "RoleBinding '$MONITOR_RB' must reference Role '$MONITOR_ROLE'."

jq_match \
  '.subjects[]? | select(.kind=="ServiceAccount" and .name==$sa and .namespace==$ns)' \
  --arg sa "$MONITOR_SA" --arg ns "$NS" <<< "$MRB_JSON" \
  || fail "RoleBinding '$MONITOR_RB' must bind ServiceAccount '$MONITOR_SA' in namespace '$NS'."
pass "RoleBinding '$MONITOR_RB' binds '$MONITOR_ROLE' → '$MONITOR_SA'"

MONITOR_DEP_SA="$(kubectl -n "$NS" get deploy "$MONITOR_DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$MONITOR_DEP_SA" == "$MONITOR_SA" ]] \
  || fail "Deployment '$MONITOR_DEP' uses ServiceAccount '${MONITOR_DEP_SA:-default}', expected '$MONITOR_SA'."
pass "Deployment '$MONITOR_DEP' uses ServiceAccount '$MONITOR_SA'"

kubectl -n "$NS" rollout status "deploy/$MONITOR_DEP" --timeout=180s >/dev/null 2>&1 \
  || fail "Deployment '$MONITOR_DEP' is not ready."
pass "Deployment '$MONITOR_DEP' is ready"

# ===========================================================================
echo ""
echo "── Effective permission test (kubectl auth can-i) ─────────────────"

if [[ "$(kubectl auth can-i --as="system:serviceaccount:${NS}:${SA}" list deployments -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$SA' is STILL denied from listing deployments. Double-check your Role and RoleBinding."
fi
pass "ServiceAccount '$SA' CAN list deployments in '$NS'"

if [[ "$(kubectl auth can-i --as="system:serviceaccount:${NS}:${MONITOR_SA}" list deployments -n "$NS")" != "yes" ]]; then
  fail "ServiceAccount '$MONITOR_SA' is STILL denied from listing deployments. Double-check your Role and RoleBinding."
fi
pass "ServiceAccount '$MONITOR_SA' CAN list deployments in '$NS'"

# ===========================================================================
echo ""
echo "==========================================="
echo "✅ All checks passed! RBAC is correctly"
echo "   configured for both deployments."
echo "==========================================="
echo ""
echo "Tip – check live logs:"
echo "  kubectl logs deployment/$DEP        -n $NS --tail=5"
echo "  kubectl logs deployment/$MONITOR_DEP -n $NS --tail=5"

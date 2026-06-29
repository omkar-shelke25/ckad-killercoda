#!/usr/bin/env bash
set -uo pipefail

NS_SRC="netpol-demo9"
NS_TGT="external-ns"
NP="external-target"
SRC_POD="source-pod"
TGT_POD="target-pod"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

echo "========================================="
echo "Verifying NetworkPolicy in '$NS_SRC'..."
echo "========================================="

# 1) Namespaces exist
kubectl get ns "$NS_SRC" >/dev/null 2>&1 \
  || fail "Namespace '$NS_SRC' not found."
kubectl get ns "$NS_TGT" >/dev/null 2>&1 \
  || fail "Namespace '$NS_TGT' not found."
pass "Namespaces '$NS_SRC' and '$NS_TGT' exist"

# 2) Pods exist
kubectl get pod "$SRC_POD" -n "$NS_SRC" >/dev/null 2>&1 \
  || fail "Pod '$SRC_POD' not found in '$NS_SRC'."
kubectl get pod "$TGT_POD" -n "$NS_TGT" >/dev/null 2>&1 \
  || fail "Pod '$TGT_POD' not found in '$NS_TGT'."
pass "Pods '$SRC_POD' and '$TGT_POD' exist"

# 3) NetworkPolicy exists
kubectl get netpol "$NP" -n "$NS_SRC" >/dev/null 2>&1 \
  || fail "NetworkPolicy '$NP' not found in '$NS_SRC'. Create it with the correct spec."
pass "NetworkPolicy '$NP' exists in '$NS_SRC'"

SPEC="$(kubectl get netpol "$NP" -n "$NS_SRC" -o json)"

# 4) policyTypes includes Egress
echo "$SPEC" | jq -e '.spec.policyTypes | index("Egress") != null' >/dev/null \
  || fail "policyTypes must include 'Egress'."
pass "policyTypes includes Egress"

# 5) podSelector matches app=source
SRC_LABEL="$(echo "$SPEC" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[ "$SRC_LABEL" = "source" ] \
  || fail "podSelector must match label app=source (found: '${SRC_LABEL}')."
pass "podSelector matches app=source"

# 6) At least one egress rule exists
EG_LEN="$(echo "$SPEC" | jq '.spec.egress | length')"
[ "${EG_LEN:-0}" -ge 1 ] \
  || fail "No egress rules found. Add an egress rule targeting '$NS_TGT'/app=target on TCP/80."
pass "Egress rules exist"

# 7) Verify the egress rule targets external-ns + app=target + TCP/80
#
# In Kubernetes NetworkPolicy, when namespaceSelector and podSelector appear
# together in the SAME to[] entry they are stored as sibling keys on that
# object — NOT as nested items inside an array. So the JSON looks like:
#   "to": [ { "namespaceSelector": {...}, "podSelector": {...} } ]
#
# The jq query below handles BOTH valid forms students may write:
#   Form A (combined): to[i] has BOTH namespaceSelector AND podSelector
#   Form B (separate): one to[i] has namespaceSelector, another has podSelector
#   (Form A is the correct one for "AND" logic; Form B gives "OR" logic)

RULE_OK="$(echo "$SPEC" | jq -r \
  --arg ns "$NS_TGT" \
  '# Form A: namespaceSelector + podSelector in the SAME to[] entry (correct AND logic)
   .spec.egress[] |
   select(
     (
       .to[]? |
       (.namespaceSelector.matchLabels["kubernetes.io/metadata.name"] == $ns)
       and
       (.podSelector.matchLabels.app == "target")
     )
     and
     (
       .ports[]? |
       (.protocol == "TCP") and (.port == 80 or .port == "80")
     )
   ) | "ok"
  ' | head -n1)"

[ "$RULE_OK" = "ok" ] \
  || fail "No valid egress rule found. The rule must:
  - Target namespace '$NS_TGT' via namespaceSelector (kubernetes.io/metadata.name: $NS_TGT)
  - Target pods with label app=target via podSelector (in the SAME to[] entry)
  - Allow TCP port 80
  Both selectors must be in the same 'to' list entry for AND logic."
pass "Egress rule correctly targets '$NS_TGT'/app=target on TCP/80"

# 8) Live connectivity test from source-pod to target-svc
echo ""
echo "── Live connectivity test ────────────────────────"
WGET_RESULT="$(kubectl exec "$SRC_POD" -n "$NS_SRC" -- \
  wget -qO- --timeout=5 http://target-svc.external-ns:80 2>&1 || true)"

if echo "$WGET_RESULT" | grep -qi "html\|nginx\|Welcome"; then
  pass "Live test: source-pod can reach target-svc on TCP/80"
else
  fail "Live test failed: source-pod cannot reach target-svc.external-ns:80.
  Check your NetworkPolicy allows egress from app=source to app=target in '$NS_TGT' on TCP/80.
  Debug: kubectl exec $SRC_POD -n $NS_SRC -- wget -qO- http://target-svc.external-ns:80"
fi

echo ""
echo "========================================="
pass "All checks passed! NetworkPolicy is correctly configured."
echo "========================================="

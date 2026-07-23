#!/bin/bash
# Verification script for NetworkPolicy np1 (Egress with DNS exception)
set -uo pipefail

NS="venus"
NP="np1"

pass() { echo "PASS: $1"; exit 0; }
fail() { echo "FAIL: $1"; exit 1; }
ok()   { echo "  ok: $1"; }

# -- Prerequisites --
kubectl get ns "$NS" >/dev/null 2>&1 \
  || fail "Namespace '$NS' not found"
ok "Namespace '$NS' exists"

kubectl -n "$NS" get deploy api >/dev/null 2>&1 \
  || fail "Deployment 'api' not found in '$NS'"
ok "Deployment 'api' exists"

kubectl -n "$NS" get deploy frontend >/dev/null 2>&1 \
  || fail "Deployment 'frontend' not found in '$NS'"
ok "Deployment 'frontend' exists"

# -- NetworkPolicy exists --
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 \
  || fail "NetworkPolicy '$NP' not found in '$NS' — make sure it is named exactly 'np1'"
ok "NetworkPolicy '$NP' exists"

spec_json="$(kubectl -n "$NS" get networkpolicy "$NP" -o json)"

# -- Targets app=frontend --
app_label="$(echo "$spec_json" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[[ "$app_label" == "frontend" ]] \
  || fail "podSelector must target label app=frontend (found: '$app_label')"
ok "podSelector targets app=frontend"

# -- policyTypes includes Egress --
echo "$spec_json" | jq -e '.spec.policyTypes | index("Egress") != null' >/dev/null \
  || fail "policyTypes must include 'Egress'"
ok "policyTypes includes Egress"

# -- At least one egress rule targets pods labeled app=api --
echo "$spec_json" \
  | jq -e '[.spec.egress[]?.to[]?.podSelector.matchLabels.app] | index("api") != null' >/dev/null \
  || fail "No egress rule targets pods with label app=api"
ok "Egress rule targets app=api pods"

# -- TCP/2222 is allowed in egress --
echo "$spec_json" \
  | jq -e '[.spec.egress[].ports[]? | select(.port == 2222 and ((.protocol // "TCP") == "TCP"))] | length > 0' >/dev/null \
  || fail "No egress rule allows TCP port 2222"
ok "Egress allows TCP/2222"

# -- UDP/53 is allowed in egress (DNS) --
echo "$spec_json" \
  | jq -e '[.spec.egress[].ports[]? | select(.port == 53 and .protocol == "UDP")] | length > 0' >/dev/null \
  || fail "No egress rule allows UDP/53 — DNS will not work"
ok "Egress allows UDP/53 (DNS)"

# -- TCP/53 is allowed in egress (DNS fallback) --
echo "$spec_json" \
  | jq -e '[.spec.egress[].ports[]? | select(.port == 53 and ((.protocol // "TCP") == "TCP"))] | length > 0' >/dev/null \
  || fail "No egress rule allows TCP/53 — DNS fallback will not work"
ok "Egress allows TCP/53 (DNS)"

# -- Functional checks --
FPOD="$(kubectl -n "$NS" get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
[[ -n "$FPOD" ]] \
  || fail "No running pod found for Deployment 'frontend' in '$NS'"
ok "Frontend pod: $FPOD"

# DNS must resolve from the frontend pod
kubectl -n "$NS" exec "$FPOD" -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  || fail "DNS lookup failed from frontend pod — check that UDP/53 and TCP/53 are allowed in egress"
ok "DNS resolution works from frontend pod"

# api:2222 must be reachable from the frontend pod
kubectl -n "$NS" exec "$FPOD" -- wget -qO- --timeout=5 http://api:2222 >/dev/null 2>&1 \
  || fail "Could not reach http://api:2222 from frontend pod — check that TCP/2222 to app=api is allowed"
ok "http://api:2222 is reachable from frontend pod"

# www.google.com must be blocked from the frontend pod
if kubectl -n "$NS" exec "$FPOD" -- wget -qO- --timeout=5 http://www.google.com >/dev/null 2>&1; then
  fail "http://www.google.com was reachable from frontend pod — it should be blocked by np1"
fi
ok "http://www.google.com is blocked from frontend pod"

pass "NetworkPolicy np1 is correct: frontend egress is restricted to api:2222 and DNS (UDP+TCP/53) only"

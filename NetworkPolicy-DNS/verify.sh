#!/bin/bash
# Verification script for "deny-all-except-dns" NetworkPolicy
set -euo pipefail

ns="netpol-demo2"
np="deny-all-except-dns"
pod_name="isolated"

fail() { echo "❌ $1"; exit 1; }
ok() { echo "✓ $1"; }

command -v kubectl >/dev/null 2>&1 || fail "kubectl not found in PATH"
command -v jq >/dev/null 2>&1 || fail "jq not found in PATH"

kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found"
ok "Namespace '$ns' exists"

kubectl get pod "$pod_name" -n "$ns" >/dev/null 2>&1 || fail "Pod '$pod_name' not found in '$ns'"
ok "Pod '$pod_name' exists in '$ns'"

kubectl get netpol "$np" -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy '$np' not found in '$ns'"
ok "NetworkPolicy '$np' exists"

spec_json="$(kubectl get netpol "$np" -n "$ns" -o json)"

echo "$spec_json" | jq -e '.spec.policyTypes | index("Ingress")' >/dev/null \
  || fail "policyTypes missing 'Ingress'"
echo "$spec_json" | jq -e '.spec.policyTypes | index("Egress")'  >/dev/null \
  || fail "policyTypes missing 'Egress'"
ok "policyTypes include Ingress and Egress"

app_label="$(echo "$spec_json" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[[ "$app_label" == "isolated" ]] || fail "podSelector does not target label app=isolated"
ok "podSelector targets app=isolated"

# ✅ Ingress default deny: accept [] *or* null/absent
echo "$spec_json" | jq -e '((.spec.ingress // []) | length) == 0' >/dev/null \
  || fail "ingress should be empty (default deny)"
ok "ingress is empty (default deny)"

# Egress: exactly one rule
eg_len="$(echo "$spec_json" | jq '.spec.egress | length')"
[[ "$eg_len" -eq 1 ]] || fail "egress should contain exactly 1 rule"
ok "egress has exactly one rule"

# Egress: that rule has exactly one port and it is UDP/53
ports_len="$(echo "$spec_json" | jq '.spec.egress[0].ports | length')"
[[ "$ports_len" -eq 1 ]] || fail "egress rule should have exactly 1 port"
proto="$(echo "$spec_json" | jq -r '.spec.egress[0].ports[0].protocol // "UDP"')"
portv="$(echo "$spec_json" | jq -r '.spec.egress[0].ports[0].port')"
[[ "$proto" == "UDP" && ( "$portv" == "53" || "$portv" -eq 53 ) ]] || fail "egress port must be UDP/53"
ok "egress allows only UDP/53"

# Egress: no destinations restricted
echo "$spec_json" | jq -e '((.spec.egress[0].to // []) | length) == 0' >/dev/null \
  || fail "egress rule should not restrict destinations with 'to:' (should be absent/empty)"
ok "egress has no destination restrictions (DNS to anywhere)"

echo "✅ Verification successful! NetworkPolicy '$np' in namespace '$ns' matches the expected DNS-only egress (UDP/53) with default-deny ingress."

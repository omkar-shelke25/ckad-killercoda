#!/bin/bash
# Verification script for DNS-only egress NetworkPolicy
set -euo pipefail

ns="netpol-demo2"
np="deny-all-except-dns"
pod="isolated"

fail() { echo "❌ $1"; exit 1; }
ok() { echo "✓ $1"; }

# 1) Namespace
kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found"
ok "Namespace '$ns' exists"

# 2) Pod
kubectl get pod "$pod" -n "$ns" >/dev/null 2>&1 || fail "Pod '$pod' not found in '$ns'"
ok "Pod '$pod' exists in '$ns'"

# 3) NetworkPolicy
kubectl get netpol "$np" -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy '$np' not found in '$ns'"
ok "NetworkPolicy '$np' exists"

# 4) Validate spec using jq (commonly available on KillerCoda images)
spec_json="$(kubectl get netpol "$np" -n "$ns" -o json)"

# policyTypes must include Ingress and Egress
echo "$spec_json" | jq -e '.spec.policyTypes|index("Ingress")' >/dev/null || fail "policyTypes missing 'Ingress'"
echo "$spec_json" | jq -e '.spec.policyTypes|index("Egress")'  >/dev/null || fail "policyTypes missing 'Egress'"
ok "policyTypes include Ingress and Egress"

# Pod selector must target app=isolated
app_label="$(echo "$spec_json" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[[ "$app_label" == "isolated" ]] || fail "podSelector does not target label app=isolated"
ok "podSelector targets app=isolated"

# Ingress default deny (empty array)
echo "$spec_json" | jq -e '.spec.ingress|type=="array" and (.spec.ingress|length==0)' >/dev/null || fail "ingress should be an empty array (default deny)"
ok "ingress is empty (default deny)"

# Egress allows ONLY UDP/53 (exactly one rule with one port)
eg_len="$(echo "$spec_json" | jq '.spec.egress|length')"
[[ "$eg_len" -eq 1 ]] || fail "egress should contain exactly 1 rule"
ports_len="$(echo "$spec_json" | jq '.spec.egress[0].ports|length')"
[[ "$ports_len" -eq 1 ]] || fail "egress rule should have exactly 1 port"
proto="$(echo "$spec_json" | jq -r '.spec.egress[0].ports[0].protocol')"
portv="$(echo "$spec_json" | jq -r '.spec.egress[0].ports[0].port')"
[[ "$proto" == "UDP" && ( "$portv" == "53" || "$portv" -eq 53 ) ]] || fail "egress port must be UDP/53"
ok "egress allows only UDP/53"

echo "✅ Verification successful! NetworkPolicy is correctly configured."

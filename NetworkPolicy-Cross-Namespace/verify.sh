#!/usr/bin/env bash
set -euo pipefail

ns_src="netpol-demo9"
ns_tgt="external-ns"
np="external-target"
src_pod="source-pod"
tgt_pod="target-pod"

fail(){ echo "❌ $1"; exit 1; }
ok(){ echo "✓ $1"; }

# Namespaces
kubectl get ns "$ns_src" >/dev/null 2>&1 || fail "Namespace '$ns_src' not found"
kubectl get ns "$ns_tgt" >/dev/null 2>&1 || fail "Namespace '$ns_tgt' not found"
ok "Namespaces '$ns_src' and '$ns_tgt' exist"

# Pods
kubectl get pod "$src_pod" -n "$ns_src" >/dev/null 2>&1 || fail "Pod '$src_pod' not found in '$ns_src'"
kubectl get pod "$tgt_pod" -n "$ns_tgt" >/dev/null 2>&1 || fail "Pod '$tgt_pod' not found in '$ns_tgt'"
ok "Pods '$src_pod' and '$tgt_pod' exist"

# NetworkPolicy
kubectl get netpol "$np" -n "$ns_src" >/dev/null 2>&1 || fail "NetworkPolicy '$np' not found in '$ns_src'"
ok "NetworkPolicy '$np' exists in '$ns_src'"

spec="$(kubectl get netpol "$np" -n "$ns_src" -o json)"

# policyTypes contains Egress
echo "$spec" | jq -e '.spec.policyTypes|index("Egress")' >/dev/null || fail "policyTypes must include 'Egress'"
ok "policyTypes includes Egress"

# podSelector matches app=source
src_label="$(echo "$spec" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[[ "$src_label" == "source" ]] || fail "podSelector must match label app=source"
ok "podSelector matches app=source"

# egress has at least one rule
eg_len="$(echo "$spec" | jq '.spec.egress|length')"
[[ "$eg_len" -ge 1 ]] || fail "egress must contain at least 1 rule"
ok "egress has rules"

# Find a rule that has namespaceSelector for external-ns and podSelector app=target and port TCP/80
match_rule=$(echo "$spec" | jq -e \
  --arg ns "$ns_tgt" \
  '.spec.egress[] | select(
     (.to[]? | (.namespaceSelector.matchLabels["kubernetes.io/metadata.name"] == $ns)
      and (.podSelector.matchLabels.app == "target"))
     and (.ports[]? | (.protocol=="TCP" and (.port==80 or .port=="80")))
   )')

if [[ -z "$match_rule" ]]; then
  fail "No egress rule found that targets namespace '$ns_tgt' with pod label app=target on TCP/80"
else
  ok "Egress rule correctly targets external-ns/app=target on TCP/80"
fi

echo "✅ Verification successful!"

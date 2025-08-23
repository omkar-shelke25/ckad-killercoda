#!/usr/bin/env bash
set -euo pipefail

ns="netpol-demo1"
np="allow-frontend"

fail(){ echo "❌ $1"; exit 1; }
ok(){ echo "✓ $1"; }

# Namespace
kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found"
ok "Namespace '$ns' exists"

# Pods
kubectl get pod backend  -n "$ns" >/dev/null 2>&1 || fail "Pod 'backend' not found in '$ns'"
kubectl get pod frontend -n "$ns" >/dev/null 2>&1 || fail "Pod 'frontend' not found in '$ns'"
ok "Pods 'backend' and 'frontend' exist"

# NetworkPolicy presence
kubectl get netpol "$np" -n "$ns" >/dev/null 2>&1 || fail "NetworkPolicy '$np' not found in '$ns'"
ok "NetworkPolicy '$np' exists"

# Spec checks with jq
spec="$(kubectl get netpol "$np" -n "$ns" -o json)"

# policyTypes includes Ingress
echo "$spec" | jq -e '.spec.policyTypes|index("Ingress")' >/dev/null || fail "policyTypes must include 'Ingress'"
ok "policyTypes includes Ingress"

# podSelector -> app=backend
app_sel="$(echo "$spec" | jq -r '.spec.podSelector.matchLabels.app // empty')"
[[ "$app_sel" == "backend" ]] || fail "podSelector must match app=backend"
ok "podSelector matches app=backend"

# ingress rule exists
ing_len="$(echo "$spec" | jq '.spec.ingress|length')" || true
[[ "${ing_len:-0}" -ge 1 ]] || fail "At least one ingress rule is required"
ok "ingress rule found"

# rule allowing from pods with role=frontend on TCP/80
match_rule=$(echo "$spec" | jq -e '.spec.ingress[] |
  select(
    ((.from[]?.podSelector.matchLabels.role // "") == "frontend")
    and (.ports[]? | (.protocol=="TCP" and (.port==80 or .port=="80")))
  )')

if [[ -z "$match_rule" ]]; then
  fail "No ingress rule found allowing from pods with role=frontend on TCP/80"
else
  ok "Ingress allows role=frontend on TCP/80"
fi

echo "✅ Verification successful!"

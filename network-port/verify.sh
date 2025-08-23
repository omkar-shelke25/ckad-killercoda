#!/bin/bash
set -euo pipefail

NS="netpol-demo8"
NP="allow-frontend-and-admin"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Prereqs
for p in multi-port-pod frontend admin; do
  kubectl -n "$NS" get pod "$p" >/dev/null 2>&1 || fail "Missing pod '$p' in '$NS'."
  kubectl -n "$NS" wait --for=condition=Ready pod/"$p" --timeout=180s >/dev/null 2>&1 || fail "Pod '$p' not Ready."
done
pass "Pods are present and Ready."

# NetworkPolicy presence
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 || fail "NetworkPolicy '$NP' not found in '$NS'."

# Structural checks
PT="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.policyTypes[*]}')"
echo "$PT" | grep -qw "Ingress" || fail "policyTypes must include Ingress."

# Target selection should match the app=multi-port pod
SEL="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.podSelector.matchLabels.app}')"
[ "$SEL" = "multi-port" ] || fail "podSelector should target label app=multi-port. Found: app='$SEL'"

# Expect two distinct ingress rules
ING_COUNT="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.ingress[*]}' | wc -w | tr -d ' ')"
[ "$ING_COUNT" -ge 1 ] || fail "Expected ingress rules defined."

# Use more robust checks with jsonpath instead of grep
# Check for port 80 rule
PORT_80_EXISTS="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.ingress[*].ports[?(@.port==80)]}')"
[ -n "$PORT_80_EXISTS" ] || fail "Expected port 80 in ingress rules."

# Check for port 443 rule  
PORT_443_EXISTS="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.ingress[*].ports[?(@.port==443)]}')"
[ -n "$PORT_443_EXISTS" ] || fail "Expected port 443 in ingress rules."

# Check for frontend role selector (more flexible approach)
FRONTEND_RULE="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.role}' | tr ' ' '\n' | grep -c '^frontend$' || echo 0)"
[ "$FRONTEND_RULE" -gt 0 ] || fail "Expected from pods with role=frontend."

# Check for admin role selector
ADMIN_RULE="$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.role}' | tr ' ' '\n' | grep -c '^admin$' || echo 0)"
[ "$ADMIN_RULE" -gt 0 ] || fail "Expected from pods with role=admin."

pass "NetworkPolicy structure looks correct."

# Functional checks
TARGET_IP="$(kubectl -n "$NS" get pod multi-port-pod -o jsonpath='{.status.podIP}')"
[ -n "$TARGET_IP" ] || fail "Could not get target pod IP."

try_nc () {
  local ns="$1"; local pod="$2"; local ip="$3"; local port="$4"
  kubectl -n "$ns" exec "$pod" -- sh -c "nc -z -w 2 ${ip} ${port} >/dev/null 2>&1"; echo $?
}

# 1) frontend -> 80 should SUCCEED
RC=$(try_nc "$NS" frontend "$TARGET_IP" 80)
[ "$RC" -eq 0 ] || fail "Expected frontend -> 80 to succeed (rc=$RC)."
pass "frontend -> 80 allowed."

# 2) frontend -> 443 should FAIL
RC=$(try_nc "$NS" frontend "$TARGET_IP" 443)
[ "$RC" -ne 0 ] || fail "Expected frontend -> 443 to be denied (rc=$RC)."
pass "frontend -> 443 denied."

# 3) admin -> 443 should SUCCEED
RC=$(try_nc "$NS" admin "$TARGET_IP" 443)
[ "$RC" -eq 0 ] || fail "Expected admin -> 443 to succeed (rc=$RC)."
pass "admin -> 443 allowed."

# 4) admin -> 80 should FAIL
RC=$(try_nc "$NS" admin "$TARGET_IP" 80)
[ "$RC" -ne 0 ] || fail "Expected admin -> 80 to be denied (rc=$RC)."
pass "admin -> 80 denied."

echo "✅ Verification successful! NetworkPolicy '$NP' enforces per-port peers in '$NS'."

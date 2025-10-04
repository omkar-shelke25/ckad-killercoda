#!/usr/bin/env bash
# verify.sh - Verify NetworkPolicy np-redis in namespace jupiter
# Usage: ./verify.sh
set -euo pipefail

NS="jupiter"
NP="np-redis"

fail() {
  echo "✖ FAIL: $*" >&2
  exit 1
}

ok() {
  echo "✔ OK: $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found in PATH"
}

# Check kubectl exists
require_cmd kubectl

# Check policy exists
if ! kubectl get networkpolicy -n "$NS" "$NP" >/dev/null 2>&1; then
  fail "NetworkPolicy '$NP' not found in namespace '$NS'"
fi
ok "NetworkPolicy '$NP' exists in namespace '$NS'"

# Try to get JSON for parsing. Prefer jq if available.
JSON="$(kubectl get networkpolicy -n "$NS" "$NP" -o json)"

if command -v jq >/dev/null 2>&1; then
  # Using jq for robust checks
  # 1) podSelector app: redis
  sel_app=$(echo "$JSON" | jq -r '.spec.podSelector.matchLabels.app // empty')
  if [ "$sel_app" != "redis" ]; then
    fail "podSelector.matchLabels.app != 'redis' (found: '${sel_app:-<none>}')"
  fi
  ok "podSelector.matchLabels.app == 'redis'"

  # 2) policyTypes contains Ingress and Egress
  types=$(echo "$JSON" | jq -r '.spec.policyTypes[]' | tr '\n' ' ')
  echo "Detected policyTypes: $types"
  echo "$types" | grep -qw Ingress || fail "policyTypes does not include 'Ingress'"
  echo "$types" | grep -qw Egress  || fail "policyTypes does not include 'Egress'"
  ok "policyTypes includes Ingress and Egress"

  # 3) ingress: has rule with ports -> tcp 6379 and from podSelectors app=app1 and app=app2
  # Check at least one ingress rule with port 6379/tcp
  ingress_has_6379=$(echo "$JSON" | jq '[.spec.ingress[]?.ports[]? | select(.protocol=="TCP" and (.port==6379 or .port=="6379"))] | length')
  if [ "$ingress_has_6379" = "0" ]; then
    fail "No ingress port TCP:6379 found"
  fi
  ok "Ingress includes TCP port 6379"

  # Check from selectors include app=app1 and app=app2
  # Collect all ingress from podSelector matchLabels.app values
  ingress_from_apps=$(echo "$JSON" | jq -r '.spec.ingress[]?.from[]?.podSelector.matchLabels.app // empty' | grep -v '^$' | sort -u || true)
  echo "Ingress 'from' podSelector apps found: ${ingress_from_apps:-<none>}"
  echo "$ingress_from_apps" | grep -qw app1 || fail "Ingress 'from' does not include podSelector app=app1"
  echo "$ingress_from_apps" | grep -qw app2 || fail "Ingress 'from' does not include podSelector app=app2"
  ok "Ingress 'from' includes podSelector app=app1 and app=app2"

  # 4) egress: ports include UDP 53 and TCP 53
  # Count presence of UDP:53 and TCP:53 in egress ports
  egress_udp53=$(echo "$JSON" | jq '[.spec.egress[]?.ports[]? | select(.protocol=="UDP" and (.port==53 or .port=="53"))] | length')
  egress_tcp53=$(echo "$JSON" | jq '[.spec.egress[]?.ports[]? | select(.protocol=="TCP" and (.port==53 or .port=="53"))] | length')
  if [ "$egress_udp53" = "0" ]; then
    fail "Egress does not include UDP port 53"
  fi
  if [ "$egress_tcp53" = "0" ]; then
    fail "Egress does not include TCP port 53"
  fi
  ok "Egress includes UDP:53 and TCP:53"

  echo
  echo "ALL CHECKS PASSED: NetworkPolicy '$NP' looks correct."
  exit 0

else
  # Fallback - basic text checks using kubectl yaml and grep (less robust)
  echo "Note: 'jq' not found — doing best-effort text checks (install jq for robust checks)."

  YAML="$(kubectl get networkpolicy -n "$NS" "$NP" -o yaml)"

  echo "$YAML" | grep -q "matchLabels:" || fail "podSelector.matchLabels not found"
  echo "$YAML" | grep -q "app: redis" || fail "podSelector.matchLabels.app != 'redis'"

  echo "$YAML" | grep -q "policyTypes:" || fail "policyTypes not found"
  echo "$YAML" | grep -q "Ingress" || fail "policyTypes does not include 'Ingress'"
  echo "$YAML" | grep -q "Egress"  || fail "policyTypes does not include 'Egress'"

  # ingress port 6379 tcp
  echo "$YAML" | grep -A3 "ingress:" | grep -q "port: 6379" || fail "ingress port 6379 not found (text fallback)"
  # verify 'from' app1 and app2
  echo "$YAML" | grep -A6 "podSelector:" | grep -q "app: app1" || fail "ingress 'from' app=app1 not found (text fallback)"
  echo "$YAML" | grep -A6 "podSelector:" | grep -q "app: app2" || fail "ingress 'from' app=app2 not found (text fallback)"

  # egress ports 53 TCP and UDP
  echo "$YAML" | grep -A6 "egress:" | grep -q "port: 53" || fail "egress port 53 not found (text fallback)"
  # crude checks for protocol presence
  echo "$YAML" | grep -A6 "egress:" | grep -q "protocol: UDP" || fail "egress protocol UDP not found (text fallback)"
  echo "$YAML" | grep -A6 "egress:" | grep -q "protocol: TCP" || fail "egress protocol TCP not found (text fallback)"

  ok "Basic text checks passed (but install 'jq' for more reliable verification)."
  exit 0
fi

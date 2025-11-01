#!/usr/bin/env bash
# verify.sh - Verify NetworkPolicy np-redis in namespace jupiter
# Usage:
#   ./verify.sh           # verify spec only (requires kubectl, jq recommended)
#   ./verify.sh --nettest # also attempt live connectivity tests (requires nc inside test pods)
set -euo pipefail

NS="jupiter"
NP="np-redis"

# CLI options
NETTEST=false
for arg in "$@"; do
  case "$arg" in
    --nettest) NETTEST=true ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--nettest]
  --nettest  Attempt actual connectivity tests (will only run if 'nc' is present inside pods)
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $arg"; exit 2 ;;
  esac
done

fail() {
  echo "✖ FAIL: $*" >&2
  exit 1
}

ok() {
  echo "✔ OK: $*"
}

warn() {
  echo "⚠ WARN: $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found in PATH"
}

require_cmd kubectl

# Ensure namespace exists
if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  fail "Namespace '$NS' does not exist or is not accessible"
fi

# Ensure NetworkPolicy exists
if ! kubectl get networkpolicy -n "$NS" "$NP" >/dev/null 2>&1; then
  fail "NetworkPolicy '$NP' not found in namespace '$NS'"
fi
ok "NetworkPolicy '$NP' exists in namespace '$NS'"

# Get JSON/YAML
JSON="$(kubectl -n "$NS" get networkpolicy "$NP" -o json)"

# Prefer jq for robust checks
if command -v jq >/dev/null 2>&1; then
  # 1) podSelector app: redis
  sel_app=$(echo "$JSON" | jq -r '.spec.podSelector.matchLabels.app // empty')
  if [ "$sel_app" != "redis" ]; then
    fail "podSelector.matchLabels.app != 'redis' (found: '${sel_app:-<none>}')"
  fi
  ok "podSelector.matchLabels.app == 'redis'"

  # 2) policyTypes includes Ingress and Egress
  # Collect types into space-separated string
  types=$(echo "$JSON" | jq -r '[.spec.policyTypes[]?] | unique | join(" ")')
  echo "Detected policyTypes: ${types:-<none>}"
  echo "$types" | grep -qw Ingress || fail "policyTypes does not include 'Ingress'"
  echo "$types" | grep -qw Egress  || fail "policyTypes does not include 'Egress'"
  ok "policyTypes includes Ingress and Egress"

  # 3) ingress: at least one rule with TCP port 6379
  ingress_has_6379=$(echo "$JSON" | jq '[.spec.ingress[]?.ports[]? | select(((.protocol//"TCP") == "TCP") and ((.port==6379) or (.port=="6379")))] | length')
  if [ "$ingress_has_6379" -eq 0 ]; then
    fail "No ingress rule was found that allows TCP port 6379"
  fi
  ok "Ingress includes TCP port 6379"

  # 3b) ingress 'from' should include podSelector matchLabels.app == app1 and app2
  ingress_from_apps=$(echo "$JSON" | jq -r '[.spec.ingress[]?.from[]?.podSelector.matchLabels.app? // empty] | map(select(. != "")) | unique | .[]' 2>/dev/null || true)
  if [ -z "${ingress_from_apps:-}" ]; then
    echo "Ingress 'from' podSelector apps found: <none>"
  else
    echo "Ingress 'from' podSelector apps found:"
    echo "$ingress_from_apps" | sed 's/^/  - /'
  fi

  echo "$ingress_from_apps" | grep -qw app1 || fail "Ingress 'from' does not include podSelector app=app1"
  echo "$ingress_from_apps" | grep -qw app2 || fail "Ingress 'from' does not include podSelector app=app2"
  ok "Ingress 'from' includes podSelector app=app1 and app=app2"

  # 4) egress: includes UDP:53 and TCP:53 (may be in same or separate rules)
  egress_udp53=$(echo "$JSON" | jq '[.spec.egress[]?.ports[]? | select(((.protocol//"UDP") == "UDP") and ((.port==53) or (.port=="53")))] | length')
  egress_tcp53=$(echo "$JSON" | jq '[.spec.egress[]?.ports[]? | select(((.protocol//"TCP") == "TCP") and ((.port==53) or (.port=="53")))] | length')
  if [ "$egress_udp53" -eq 0 ]; then
    fail "Egress does not include UDP port 53"
  fi
  if [ "$egress_tcp53" -eq 0 ]; then
    fail "Egress does not include TCP port 53"
  fi
  ok "Egress includes UDP:53 and TCP:53"

  ok "ALL SPEC CHECKS PASSED: NetworkPolicy '$NP' looks correct."

else
  # Fallback text checks (less robust)
  warn "'jq' not found — doing best-effort text checks (install jq for robust verification)."
  YAML="$(kubectl -n "$NS" get networkpolicy "$NP" -o yaml)"

  echo "$YAML" | grep -q "matchLabels:" || fail "podSelector.matchLabels not found"
  echo "$YAML" | grep -q "app: redis" || fail "podSelector.matchLabels.app != 'redis'"

  echo "$YAML" | grep -q "policyTypes:" || fail "policyTypes not found"
  echo "$YAML" | grep -q "Ingress" || fail "policyTypes does not include 'Ingress'"
  echo "$YAML" | grep -q "Egress"  || fail "policyTypes does not include 'Egress'"

  # ingress port 6379 tcp (text match)
  echo "$YAML" | grep -A3 "ingress:" | grep -q "port: 6379" || fail "ingress port 6379 not found (text fallback)"
  # verify 'from' app1 and app2 crude
  echo "$YAML" | grep -q "app: app1" || fail "ingress 'from' app=app1 not found (text fallback)"
  echo "$YAML" | grep -q "app: app2" || fail "ingress 'from' app=app2 not found (text fallback)"

  # egress ports 53 TCP and UDP crude checks
  echo "$YAML" | grep -A6 "egress:" | grep -q "port: 53" || fail "egress port 53 not found (text fallback)"
  echo "$YAML" | grep -A6 "egress:" | grep -q "protocol: UDP" || fail "egress protocol UDP not found (text fallback)"
  echo "$YAML" | grep -A6 "egress:" | grep -q "protocol: TCP" || fail "egress protocol TCP not found (text fallback)"

  ok "Basic text checks passed (but install 'jq' for more reliable verification)."
fi

# Optional: perform live connectivity tests if requested
if [ "$NETTEST" = true ]; then
  echo
  ok "NETTEST requested — attempting runtime connectivity tests (will only run if pods have 'nc' inside)."

  # Helper: pick first pod for label, ensure pods exist
  pick_pod_for_label() {
    local label="$1"
    pod=$(kubectl -n "$NS" get pods -l "app=${label}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
    if [ -z "$pod" ]; then
      echo ""
    else
      echo "$pod"
    fi
  }

  APP1_POD=$(pick_pod_for_label app1)
  APP2_POD=$(pick_pod_for_label app2)
  REDIS_POD=$(pick_pod_for_label redis)
  TEST_POD=$(pick_pod_for_label test-pod || true)

  [ -n "$APP1_POD" ] || fail "No pod found with label app=app1 in namespace $NS"
  [ -n "$APP2_POD" ] || fail "No pod found with label app=app2 in namespace $NS"
  [ -n "$REDIS_POD" ] || fail "No pod found with label app=redis in namespace $NS"

  echo "Selected pods:"
  echo "  app1 -> $APP1_POD"
  echo "  app2 -> $APP2_POD"
  echo "  redis -> $REDIS_POD"
  if [ -n "$TEST_POD" ]; then
    echo "  test-pod -> $TEST_POD"
  else
    echo "  test-pod -> <none found> (skipping test-pod connectivity check)"
  fi

  # Check if 'nc' is present in app1/app2/test pods (need at least in app1/app2 to test)
  has_nc() {
    local pod="$1"
    kubectl -n "$NS" exec -i "$pod" -- sh -c 'command -v nc >/dev/null 2>&1' >/dev/null 2>&1 && return 0 || return 1
  }

  if ! has_nc "$APP1_POD" && ! has_nc "$APP2_POD"; then
    warn "Neither app1 nor app2 pods contain 'nc'. Skipping live nc connectivity tests. (You can install netcat or run tests from another pod that has nc.)"
    exit 0
  fi

  # generic function to attempt connection using nc inside the given pod
  try_connect() {
    local from_pod="$1"
    local host="$2"
    local port="$3"
    # Use a short timeout; try both nc variants: -z -w or -z -G (some BusyBox)
    kubectl -n "$NS" exec -i "$from_pod" -- sh -c '
      if command -v nc >/dev/null 2>&1; then
        # prefer -z (zero-I/O mode) with timeout -w 2
        nc -z -w 2 '"$host"' '"$port"' >/dev/null 2>&1 && echo "SUCCESS" || echo "FAIL"
      else
        echo "NO_NC"
      fi
    ' 2>/dev/null || echo "FAIL"
  }

  echo
  echo "Testing: app1 -> redis:6379 (expected: success)"
  out=$(try_connect "$APP1_POD" "redis" "6379")
  if [ "$out" = "SUCCESS" ]; then
    ok "app1 -> redis:6379 succeeded"
  elif [ "$out" = "NO_NC" ]; then
    warn "app1 pod has no nc; cannot perform runtime connection test"
  else
    fail "app1 -> redis:6379 FAILED (but NetworkPolicy spec checks passed). If you see this, check CNI implementation and that policy is enforced."
  fi

  echo "Testing: app2 -> redis:6379 (expected: success)"
  out=$(try_connect "$APP2_POD" "redis" "6379")
  if [ "$out" = "SUCCESS" ]; then
    ok "app2 -> redis:6379 succeeded"
  elif [ "$out" = "NO_NC" ]; then
    warn "app2 pod has no nc; cannot perform runtime connection test"
  else
    fail "app2 -> redis:6379 FAILED"
  fi

  if [ -n "$TEST_POD" ]; then
    echo "Testing: test-pod -> redis:6379 (expected: fail)"
    out=$(try_connect "$TEST_POD" "redis" "6379")
    if [ "$out" = "FAIL" ]; then
      ok "test-pod -> redis:6379 correctly blocked"
    elif [ "$out" = "SUCCESS" ]; then
      fail "test-pod -> redis:6379 succeeded but should be blocked by NetworkPolicy"
    else
      warn "test-pod has no nc; cannot perform runtime connection test for test-pod"
    fi
  fi

  # DNS test from redis pod
  echo "Testing: redis pod DNS (nslookup kubernetes.default) - requires 'nslookup' or 'dig' inside redis pod."
  if kubectl -n "$NS" exec -i "$REDIS_POD" -- sh -c 'command -v nslookup >/dev/null 2>&1' >/dev/null 2>&1; then
    if kubectl -n "$NS" exec -i "$REDIS_POD" -- nslookup kubernetes.default >/dev/null 2>&1; then
      ok "redis pod can resolve DNS (nslookup kubernetes.default)"
    else
      fail "redis pod DNS lookup failed (nslookup present but failed). Ensure cluster DNS is reachable and NetworkPolicy allows UDP/TCP 53 egress."
    fi
  elif kubectl -n "$NS" exec -i "$REDIS_POD" -- sh -c 'command -v dig >/dev/null 2>&1' >/dev/null 2>&1; then
    if kubectl -n "$NS" exec -i "$REDIS_POD" -- dig +short kubernetes.default | grep -q .; then
      ok "redis pod can resolve DNS (dig)"
    else
      fail "redis pod DNS lookup failed (dig present but returned no answer)"
    fi
  else
    warn "redis pod does not contain nslookup/dig; skipping DNS runtime test. (Spec checks for DNS egress were successful.)"
  fi

  ok "NETTEST COMPLETED"
fi

exit 0

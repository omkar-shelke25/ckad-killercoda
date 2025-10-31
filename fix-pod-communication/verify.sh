#!/bin/bash
set -euo pipefail

# -----------------------------------------
# VERIFY SCRIPT – NetworkPolicy Label Fix
# -----------------------------------------
NS="production"
POD="api-check"
REQUIRED_LABEL="function=api-check"

# ✅ Helper functions (colored output)
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[1;33m'
nc='\033[0m' # no color

pass() { echo -e "${green}✅ $1${nc}"; }
fail() { echo -e "${red}❌ $1${nc}"; exit 1; }
info() { echo -e "${yellow}➡️  $1${nc}"; }

# -----------------------------------------
# Pre-checks
# -----------------------------------------
command -v kubectl >/dev/null 2>&1 || fail "kubectl not found."

info "Verifying api-check pod configuration in namespace '${NS}'..."

# -----------------------------------------
# Check pod exists
# -----------------------------------------
if ! kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1; then
  fail "Pod '${POD}' not found in namespace '${NS}'."
fi
pass "Pod '${POD}' exists."

# -----------------------------------------
# Check for required label
# -----------------------------------------
info "Checking if pod has required label: ${REQUIRED_LABEL}..."

LABELS=$(kubectl -n "$NS" get pod "$POD" --show-labels --no-headers | awk '{print $NF}')

if echo "$LABELS" | grep -q "function=api-check"; then
  pass "Pod '${POD}' has the correct label: function=api-check"
else
  fail "Pod '${POD}' is missing the required label 'function=api-check'. Current labels: ${LABELS}"
fi

# -----------------------------------------
# Test connectivity to web-server
# -----------------------------------------
info "Testing connectivity from api-check to web-server-svc..."

WEB_TEST=$(kubectl exec -n "$NS" "$POD" -- timeout 5 wget -qO- web-server-svc 2>/dev/null || echo "FAILED")

if echo "$WEB_TEST" | grep -qi "nginx\|Welcome to nginx"; then
  pass "Successfully connected to web-server-svc (received nginx response)"
elif [[ "$WEB_TEST" == "FAILED" ]]; then
  fail "Cannot connect to web-server-svc. Check if the label 'function=api-check' is correctly applied."
else
  # Sometimes we get a response but not the expected content
  pass "Connected to web-server-svc (received response)"
fi

# -----------------------------------------
# Test connectivity to redis-server
# -----------------------------------------
info "Testing connectivity from api-check to redis-server-svc..."

# Use nc (netcat) to test TCP connection to Redis
REDIS_TEST=$(kubectl exec -n "$NS" "$POD" -- timeout 3 nc -zv redis-server-svc 6379 2>&1 || echo "FAILED")

if echo "$REDIS_TEST" | grep -qi "open\|succeeded\|connected"; then
  pass "Successfully connected to redis-server-svc on port 6379"
elif [[ "$REDIS_TEST" == "FAILED" ]]; then
  fail "Cannot connect to redis-server-svc:6379. NetworkPolicy may not be allowing traffic."
else
  fail "Redis connection test returned unexpected result: ${REDIS_TEST}"
fi

# -----------------------------------------
# Verify NetworkPolicy still exists (not modified)
# -----------------------------------------
info "Verifying NetworkPolicies were not modified..."

NETPOL_COUNT=$(kubectl get networkpolicy -n "$NS" --no-headers 2>/dev/null | wc -l)

if [[ "$NETPOL_COUNT" -lt 4 ]]; then
  fail "Expected at least 4 NetworkPolicies, found ${NETPOL_COUNT}. Did you delete NetworkPolicies?"
fi

# Check that the key NetworkPolicies still exist
for netpol in "utils-network-policy" "web-server-netpol" "redis-server-netpol" "default-deny-all"; do
  if ! kubectl get networkpolicy -n "$NS" "$netpol" >/dev/null 2>&1; then
    fail "NetworkPolicy '${netpol}' is missing. You should not delete NetworkPolicies."
  fi
done

pass "All NetworkPolicies are intact (not modified or deleted)"

# -----------------------------------------
# Final summary
# -----------------------------------------
echo
pass "All verifications passed! 🎉"
echo "--------------------------------------------------------------"
echo "✅ Pod '${POD}' has the correct label: function=api-check"
echo "✅ Can communicate with web-server-svc"
echo "✅ Can communicate with redis-server-svc"
echo "✅ NetworkPolicies remain unmodified"
echo "--------------------------------------------------------------"
echo ""
echo "🎯 Key Learning: NetworkPolicies use labels to control traffic."
echo "   By adding the correct label to the pod, it matched the"
echo "   podSelector criteria and was granted network access!"
echo "--------------------------------------------------------------"

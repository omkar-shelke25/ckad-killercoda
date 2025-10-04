#!/bin/bash
set -euo pipefail

NS="jupiter"
NP="np-redis"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

echo "🔍 Verifying CKAD NetworkPolicy Exercise..."
echo ""

# 1) Check if namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS not found."
pass "Namespace $NS exists"

# 2) Check if deployments exist
for dep in app1 app2 redis; do
  kubectl -n "$NS" get deployment "$dep" >/dev/null 2>&1 || fail "Deployment $dep missing in $NS."
done
pass "All required deployments exist (app1, app2, redis)"

# 3) Check if NetworkPolicy exists
kubectl -n "$NS" get networkpolicy "$NP" >/dev/null 2>&1 || fail "NetworkPolicy '$NP' not found in namespace $NS."
pass "NetworkPolicy '$NP' exists"

# 4) Verify NetworkPolicy targets redis pods
SELECTOR=$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null || echo "")
[[ "$SELECTOR" == "redis" ]] || fail "NetworkPolicy must target pods with app=redis label (found: '$SELECTOR')."
pass "NetworkPolicy targets redis pods (app=redis)"

# 5) Verify policy types include Ingress
TYPES=$(kubectl -n "$NS" get networkpolicy "$NP" -o jsonpath='{.spec.policyTypes[*]}')
echo "$TYPES" | grep -q "Ingress" || fail "NetworkPolicy must include Ingress policy type."
pass "NetworkPolicy includes Ingress policy type"

# 6) Verify policy types include Egress (for DNS)
echo "$TYPES" | grep -q "Egress" || fail "NetworkPolicy must include Egress policy type for DNS."
pass "NetworkPolicy includes Egress policy type"

# 7) Verify ingress rules allow app1 and app2
# Get all ingress rules and check for podSelectors
INGRESS_JSON=$(kubectl -n "$NS" get networkpolicy "$NP" -o json | jq -c '.spec.ingress[]?')

HAS_APP1=false
HAS_APP2=false

while IFS= read -r rule; do
  # Check each 'from' entry in the rule
  FROM_ENTRIES=$(echo "$rule" | jq -c '.from[]?' 2>/dev/null || echo "")
  
  while IFS= read -r from_entry; do
    if [[ -n "$from_entry" ]]; then
      APP_LABEL=$(echo "$from_entry" | jq -r '.podSelector.matchLabels.app // empty' 2>/dev/null || echo "")
      
      if [[ "$APP_LABEL" == "app1" ]]; then
        HAS_APP1=true
      elif [[ "$APP_LABEL" == "app2" ]]; then
        HAS_APP2=true
      fi
    fi
  done < <(echo "$FROM_ENTRIES")
done < <(echo "$INGRESS_JSON")

[[ "$HAS_APP1" == "true" ]] || fail "NetworkPolicy must allow ingress from app=app1 pods."
[[ "$HAS_APP2" == "true" ]] || fail "NetworkPolicy must allow ingress from app=app2 pods."
pass "NetworkPolicy allows ingress from app1 and app2"

# 8) Verify ingress port 6379
HAS_PORT_6379=false
PORTS_JSON=$(kubectl -n "$NS" get networkpolicy "$NP" -o json | jq -c '.spec.ingress[]?.ports[]?' 2>/dev/null || echo "")

while IFS= read -r port_entry; do
  if [[ -n "$port_entry" ]]; then
    PORT=$(echo "$port_entry" | jq -r '.port // empty')
    PROTOCOL=$(echo "$port_entry" | jq -r '.protocol // "TCP"')
    
    if [[ "$PORT" == "6379" && "$PROTOCOL" == "TCP" ]]; then
      HAS_PORT_6379=true
    fi
  fi
done < <(echo "$PORTS_JSON")

[[ "$HAS_PORT_6379" == "true" ]] || fail "NetworkPolicy must allow ingress on TCP port 6379."
pass "NetworkPolicy allows ingress on TCP port 6379"

# 9) Verify egress for DNS (port 53 UDP and/or TCP)
HAS_DNS=false
EGRESS_PORTS=$(kubectl -n "$NS" get networkpolicy "$NP" -o json | jq -c '.spec.egress[]?.ports[]?' 2>/dev/null || echo "")

while IFS= read -r port_entry; do
  if [[ -n "$port_entry" ]]; then
    PORT=$(echo "$port_entry" | jq -r '.port // empty')
    
    if [[ "$PORT" == "53" ]]; then
      HAS_DNS=true
    fi
  fi
done < <(echo "$EGRESS_PORTS")

[[ "$HAS_DNS" == "true" ]] || fail "NetworkPolicy must allow egress on port 53 for DNS."
pass "NetworkPolicy allows egress on port 53 for DNS"

# 10) Wait for all pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl -n "$NS" wait --for=condition=Ready pods -l app=app1 --timeout=60s >/dev/null 2>&1 || fail "app1 pods not ready."
kubectl -n "$NS" wait --for=condition=Ready pods -l app=app2 --timeout=60s >/dev/null 2>&1 || fail "app2 pods not ready."
kubectl -n "$NS" wait --for=condition=Ready pods -l app=redis --timeout=60s >/dev/null 2>&1 || fail "redis pods not ready."
pass "All pods are ready"

# 11) Get pod names
APP1_POD=$(kubectl -n "$NS" get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
APP2_POD=$(kubectl -n "$NS" get pods -l app=app2 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

[[ -n "$APP1_POD" ]] || fail "app1 pod not found."
[[ -n "$APP2_POD" ]] || fail "app2 pod not found."

pass "Found test pods: $APP1_POD, $APP2_POD"

# 12) Create a temporary test pod (not app1 or app2) for negative testing
echo "⏳ Creating test pod for negative testing..."
kubectl -n "$NS" run test-connection --image=public.ecr.aws/docker/library/busybox:latest --restart=Never -- sleep 3600 2>/dev/null || true
kubectl -n "$NS" wait --for=condition=Ready pod/test-connection --timeout=60s >/dev/null 2>&1 || fail "test-connection pod not ready."
pass "Test pod created"

# 13) Wait for NetworkPolicy to take effect (with retry)
echo "⏳ Waiting for NetworkPolicy to propagate..."
sleep 10

# 14) Test connectivity with retries
test_connection() {
  local pod=$1
  local should_succeed=$2
  local max_attempts=3
  local attempt=1
  
  while [[ $attempt -le $max_attempts ]]; do
    if timeout 5 kubectl -n "$NS" exec "$pod" -- nc -zv redis 6379 >/dev/null 2>&1; then
      if [[ "$should_succeed" == "true" ]]; then
        return 0  # Success as expected
      else
        return 1  # Should have failed but succeeded
      fi
    else
      if [[ "$should_succeed" == "false" ]]; then
        return 0  # Failed as expected
      fi
    fi
    
    attempt=$((attempt + 1))
    [[ $attempt -le $max_attempts ]] && sleep 3
  done
  
  # After all retries
  if [[ "$should_succeed" == "true" ]]; then
    return 1  # Should have succeeded but failed
  else
    return 0  # Should have failed and did fail
  fi
}

# Test app1 can connect
echo "🧪 Testing app1 → redis connectivity..."
if test_connection "$APP1_POD" "true"; then
  pass "app1 can connect to redis on port 6379 ✓"
else
  fail "app1 should be able to connect to redis on port 6379"
fi

# Test app2 can connect
echo "🧪 Testing app2 → redis connectivity..."
if test_connection "$APP2_POD" "true"; then
  pass "app2 can connect to redis on port 6379 ✓"
else
  fail "app2 should be able to connect to redis on port 6379"
fi

# Test that unauthorized pod cannot connect
echo "🧪 Testing unauthorized pod → redis connectivity..."
if test_connection "test-connection" "false"; then
  pass "Unauthorized pod CANNOT connect to redis (correctly blocked) ✓"
else
  fail "Unauthorized pod should NOT be able to connect to redis on port 6379"
fi

# 15) Cleanup test pod
kubectl -n "$NS" delete pod test-connection --wait=false >/dev/null 2>&1 || true

echo ""
pass "🎉 NetworkPolicy verification successful!"
echo ""
echo "   📋 Summary:"
echo "   ✓ NetworkPolicy '$NP' exists in namespace '$NS'"
echo "   ✓ Targets redis pods (app=redis)"
echo "   ✓ Allows ingress from app1 and app2 on TCP port 6379"
echo "   ✓ Allows egress for DNS on port 53"
echo "   ✓ Blocks other pods from accessing redis"
echo ""
echo "   🔐 Security Rules Verified:"
echo "      ✅ app1 → redis:6379 (allowed)"
echo "      ✅ app2 → redis:6379 (allowed)"
echo "      ❌ other → redis:6379 (blocked)"
echo "      ✅ redis → DNS:53 (allowed for lookups)"

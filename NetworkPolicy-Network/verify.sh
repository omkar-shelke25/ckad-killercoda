#!/bin/bash
set -euo pipefail

NS="jupiter"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Check if namespace exists
kubectl get ns $NS >/dev/null 2>&1 || fail "Namespace $NS not found."

# Check if deployments exist
for dep in app1 app2 redis test-pod; do
  kubectl -n $NS get deployment $dep >/dev/null 2>&1 || fail "Deployment $dep missing in $NS."
done

# Check if NetworkPolicy exists
kubectl -n $NS get networkpolicy np-redis >/dev/null 2>&1 || fail "NetworkPolicy 'np-redis' not found in namespace $NS."

# Verify NetworkPolicy targets redis pods
SELECTOR=$(kubectl -n $NS get networkpolicy np-redis -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null || true)
[[ "$SELECTOR" == "redis" ]] || fail "NetworkPolicy must target pods with app=redis label."

# Verify policy types include Ingress
TYPES=$(kubectl -n $NS get networkpolicy np-redis -o jsonpath='{.spec.policyTypes[*]}')
echo "$TYPES" | grep -q "Ingress" || fail "NetworkPolicy must include Ingress policy type."

# Verify ingress rules allow app1 and app2
INGRESS_SELECTORS=$(kubectl -n $NS get networkpolicy np-redis -o jsonpath='{.spec.ingress[0].from[*].podSelector.matchLabels.app}' 2>/dev/null || true)
echo "$INGRESS_SELECTORS" | grep -q "app1" || fail "NetworkPolicy must allow ingress from app=app1 pods."
echo "$INGRESS_SELECTORS" | grep -q "app2" || fail "NetworkPolicy must allow ingress from app=app2 pods."

# Verify ingress port 6379
INGRESS_PORT=$(kubectl -n $NS get networkpolicy np-redis -o jsonpath='{.spec.ingress[0].ports[0].port}' 2>/dev/null || true)
[[ "$INGRESS_PORT" == "6379" ]] || fail "NetworkPolicy must allow ingress on port 6379."

# Verify egress for DNS (check if egress policy exists and includes port 53)
echo "$TYPES" | grep -q "Egress" || fail "NetworkPolicy must include Egress policy type for DNS."
EGRESS_PORTS=$(kubectl -n $NS get networkpolicy np-redis -o jsonpath='{.spec.egress[0].ports[*].port}' 2>/dev/null || true)
echo "$EGRESS_PORTS" | grep -q "53" || fail "NetworkPolicy must allow egress on port 53 for DNS."

# Test connectivity (with timeout to avoid hanging)
echo "Testing connectivity..."

# Get pod names
APP1_POD=$(kubectl -n $NS get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
APP2_POD=$(kubectl -n $NS get pods -l app=app2 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
TEST_POD=$(kubectl -n $NS get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

[[ -n "$APP1_POD" ]] || fail "app1 pod not found."
[[ -n "$APP2_POD" ]] || fail "app2 pod not found."
[[ -n "$TEST_POD" ]] || fail "test-pod not found."

# Check if pods are ready
kubectl -n $NS wait --for=condition=Ready pod/$APP1_POD --timeout=30s >/dev/null 2>&1 || fail "app1 pod not ready."
kubectl -n $NS wait --for=condition=Ready pod/$APP2_POD --timeout=30s >/dev/null 2>&1 || fail "app2 pod not ready."
kubectl -n $NS wait --for=condition=Ready pod/$TEST_POD --timeout=30s >/dev/null 2>&1 || fail "test-pod not ready."

# Wait a bit for NetworkPolicy to take effect
sleep 5

# Test that app1 can connect (should succeed)
timeout 10 kubectl -n $NS exec $APP1_POD -- nc -zv redis 6379 >/dev/null 2>&1 || fail "app1 pod should be able to connect to redis on port 6379."

# Test that app2 can connect (should succeed)  
timeout 10 kubectl -n $NS exec $APP2_POD -- nc -zv redis 6379 >/dev/null 2>&1 || fail "app2 pod should be able to connect to redis on port 6379."

# Test that test-pod cannot connect (should fail)
if timeout 10 kubectl -n $NS exec $TEST_POD -- nc -zv redis 6379 >/dev/null 2>&1; then
  fail "test-pod should NOT be able to connect to redis on port 6379."
fi

pass "NetworkPolicy np-redis correctly restricts access to redis deployment."

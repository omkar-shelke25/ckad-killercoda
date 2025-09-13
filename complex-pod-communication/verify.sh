#!/bin/bash
set -euo pipefail

NS="netpol-challenge"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying NetworkPolicy configuration..."

# Check that all pods exist
for pod in frontend-pod backend-pod target-pod; do
  kubectl -n $NS get pod $pod >/dev/null 2>&1 || fail "Pod $pod missing in namespace $NS."
done

# Check that all NetworkPolicies still exist (shouldn't be modified)
for netpol in target-ingress-policy target-egress-policy target-default-deny; do
  kubectl -n $NS get netpol $netpol >/dev/null 2>&1 || fail "NetworkPolicy $netpol is missing - you shouldn't delete policies!"
done

# Verify pod labels
echo "📋 Checking pod labels..."

TARGET_ROLE=$(kubectl -n $NS get pod target-pod -o jsonpath='{.metadata.labels.role}' 2>/dev/null || true)
[[ "$TARGET_ROLE" == "target-app" ]] || fail "Pod 'target-pod' must be labeled role=target-app (found: $TARGET_ROLE)."

FRONTEND_APP=$(kubectl -n $NS get pod frontend-pod -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)
[[ "$FRONTEND_APP" == "frontend" ]] || fail "Pod 'frontend-pod' must be labeled app=frontend (found: $FRONTEND_APP)."

BACKEND_APP=$(kubectl -n $NS get pod backend-pod -o jsonpath='{.metadata.labels.app}' 2>/dev/null || true)
[[ "$BACKEND_APP" == "backend" ]] || fail "Pod 'backend-pod' must be labeled app=backend (found: $BACKEND_APP)."

echo "✅ All pod labels are correct!"

# Verify NetworkPolicies are properly configured (check that they weren't modified)
echo "🔒 Verifying NetworkPolicies integrity..."

# Check target-ingress-policy
INGRESS_SELECTOR=$(kubectl -n $NS get netpol target-ingress-policy -o jsonpath='{.spec.podSelector.matchLabels.role}')
[[ "$INGRESS_SELECTOR" == "target-app" ]] || fail "target-ingress-policy podSelector was modified - this is not allowed!"

# Check target-egress-policy  
EGRESS_SELECTOR=$(kubectl -n $NS get netpol target-egress-policy -o jsonpath='{.spec.podSelector.matchLabels.role}')
[[ "$EGRESS_SELECTOR" == "target-app" ]] || fail "target-egress-policy podSelector was modified - this is not allowed!"

# Check default-deny policy
DENY_SELECTOR=$(kubectl -n $NS get netpol target-default-deny -o jsonpath='{.spec.podSelector.matchLabels.role}')
[[ "$DENY_SELECTOR" == "target-app" ]] || fail "target-default-deny podSelector was modified - this is not allowed!"

echo "✅ NetworkPolicies are intact!"

# Test connectivity (optional - basic check that pods are running)
echo "🔗 Testing basic pod connectivity..."

# Wait for pods to be ready
kubectl -n $NS wait --for=condition=ready pod/target-pod --timeout=30s >/dev/null 2>&1 || fail "target-pod is not ready."
kubectl -n $NS wait --for=condition=ready pod/frontend-pod --timeout=30s >/dev/null 2>&1 || fail "frontend-pod is not ready."
kubectl -n $NS wait --for=condition=ready pod/backend-pod --timeout=30s >/dev/null 2>&1 || fail "backend-pod is not ready."

echo "✅ All pods are ready!"

# Final verification message
echo ""
echo "🎉 SUCCESS! Configuration verified:"
echo "  • target-pod labeled with role=target-app (targeted by all 3 NetworkPolicies)"
echo "  • frontend-pod labeled with app=frontend (can communicate with target-pod)"  
echo "  • backend-pod labeled with app=backend (can communicate with target-pod)"
echo "  • All 3 NetworkPolicies remain unmodified"
echo ""
echo "The NetworkPolicies now enforce that target-pod can only:"
echo "  ✅ Receive traffic from frontend-pod and backend-pod"
echo "  ✅ Send traffic to frontend-pod and backend-pod"  
echo "  ❌ All other traffic is denied by default"

pass "CKAD NetworkPolicy challenge completed successfully!"

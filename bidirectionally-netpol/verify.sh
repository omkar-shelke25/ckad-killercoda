#!/bin/bash
set -euo pipefail

NAMESPACE="payment-platform"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying production environment configuration..."

# Verify all pods exist
for pod in frontend-service database-service payment-processor; do
  kubectl -n $NAMESPACE get pod $pod >/dev/null 2>&1 || fail "Pod $pod is missing in namespace $NAMESPACE."
done

# Verify pod labels are correctly configured
FRONTEND_LABEL=$(kubectl -n $NAMESPACE get pod frontend-service -o jsonpath='{.metadata.labels.tier}' 2>/dev/null || true)
[[ "$FRONTEND_LABEL" == "frontend" ]] || fail "Pod 'frontend-service' must have label tier=frontend. Current label: tier=$FRONTEND_LABEL"

DATABASE_LABEL=$(kubectl -n $NAMESPACE get pod database-service -o jsonpath='{.metadata.labels.tier}' 2>/dev/null || true)
[[ "$DATABASE_LABEL" == "database" ]] || fail "Pod 'database-service' must have label tier=database. Current label: tier=$DATABASE_LABEL"

PAYMENT_LABEL=$(kubectl -n $NAMESPACE get pod payment-processor -o jsonpath='{.metadata.labels.tier}' 2>/dev/null || true)
[[ "$PAYMENT_LABEL" == "payment" ]] || fail "Pod 'payment-processor' must have label tier=payment. Current label: tier=$PAYMENT_LABEL"

# Verify NetworkPolicies still exist and haven't been modified
NETPOL_COUNT=$(kubectl -n $NAMESPACE get networkpolicy --no-headers | wc -l)
[[ "$NETPOL_COUNT" -ge "4" ]] || fail "NetworkPolicies appear to have been modified or deleted. Found $NETPOL_COUNT policies, expected at least 4."

# Verify specific NetworkPolicies exist
for policy in default-deny-all-traffic frontend-service-policy database-service-policy payment-processor-policy; do
  kubectl -n $NAMESPACE get networkpolicy $policy >/dev/null 2>&1 || fail "NetworkPolicy '$policy' is missing or was modified."
done

# Verify the payment-processor policy allows communication with both frontend and database
PAYMENT_POLICY_INGRESS=$(kubectl -n $NAMESPACE get networkpolicy payment-processor-policy -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.tier}')
echo "$PAYMENT_POLICY_INGRESS" | grep -q "frontend" || fail "Payment processor policy should allow ingress from frontend tier."
echo "$PAYMENT_POLICY_INGRESS" | grep -q "database" || fail "Payment processor policy should allow ingress from database tier."

PAYMENT_POLICY_EGRESS=$(kubectl -n $NAMESPACE get networkpolicy payment-processor-policy -o jsonpath='{.spec.egress[*].to[*].podSelector.matchLabels.tier}')
echo "$PAYMENT_POLICY_EGRESS" | grep -q "frontend" || fail "Payment processor policy should allow egress to frontend tier."
echo "$PAYMENT_POLICY_EGRESS" | grep -q "database" || fail "Payment processor policy should allow egress to database tier."

echo ""
echo "🎉 Configuration verification successful!"
echo ""
echo "📊 Final pod configuration:"
kubectl -n $NAMESPACE get pods --show-labels
echo ""
echo "🔒 Active NetworkPolicies:"
kubectl -n $NAMESPACE get networkpolicy
echo ""

pass "Payment platform network isolation configured successfully. The payment-processor can now communicate with both frontend-service and database-service as per security requirements."

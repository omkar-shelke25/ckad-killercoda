#!/bin/bash
set -euo pipefail

NS="payment"
DEP="payment-api"

pass(){ echo "✅ $1"; exit 0; }
fail(){ echo "❌ $1"; exit 1; }

# Check namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS missing."

# Check SA exists
kubectl -n "$NS" get sa payment-sa >/dev/null 2>&1 || fail "ServiceAccount payment-sa missing."

# Check RoleBinding
kubectl -n "$NS" get rolebinding payment-secret-binding >/dev/null 2>&1 || fail "RoleBinding payment-secret-binding missing."

# Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment $DEP missing."

# Deployment spec has correct SA
SA_NAME="$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.serviceAccountName}')"
[[ "$SA_NAME" == "payment-sa" ]] || fail "Deployment $DEP must use serviceAccountName=payment-sa (found: $SA_NAME)."

# Pod uses correct SA
POD="$(kubectl -n "$NS" get pod -l app=payment-api -o jsonpath='{.items[0].metadata.name}')"
POD_SA="$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.serviceAccountName}')"
[[ "$POD_SA" == "payment-sa" ]] || fail "Pod $POD must run with SA=payment-sa (found: $POD_SA)."

pass "Deployment $DEP in $NS is now using the correct ServiceAccount 'payment-sa'."

#!/bin/bash
set -euo pipefail

NS="viper"
DEP="web-app"
MANIFEST="/ancient-tiger/app.yaml"
EXPECTED_REPLICAS=3
EXPECTED_IMAGE="public.ecr.aws/nginx/nginx:latest"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "Starting verification..."
echo ""

# 0) Check if kubectl-convert plugin is installed
if ! kubectl convert --help >/dev/null 2>&1; then
  fail "kubectl-convert plugin is not installed. Please install it before proceeding"
fi
pass "kubectl-convert plugin is installed"

# 1) Check if manifest file exists
[[ -f "$MANIFEST" ]] || fail "Manifest file not found at $MANIFEST"
pass "Manifest file exists at $MANIFEST"

# 2) Check if manifest contains deprecated API versions
if grep -q "apps/v1beta" "$MANIFEST" 2>/dev/null; then
  fail "Manifest still contains deprecated API version (apps/v1beta*). Please update to apps/v1"
fi

if grep -q "extensions/v1beta1" "$MANIFEST" 2>/dev/null; then
  fail "Manifest still contains deprecated API version (extensions/v1beta1). Please update to apps/v1"
fi

pass "No deprecated API versions found in manifest"

# 3) Check if manifest uses apps/v1
if ! grep -q "apiVersion: apps/v1" "$MANIFEST" 2>/dev/null; then
  fail "Manifest should use 'apiVersion: apps/v1' for Deployment"
fi

pass "Manifest uses correct API version (apps/v1)"

# 4) Check if namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found. Did you create it?"
pass "Namespace '$NS' exists"

# 5) Check if deployment exists in viper namespace
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'"
pass "Deployment '$DEP' exists in namespace '$NS'"

# 6) Check if deployment has correct image
ACTUAL_IMAGE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$ACTUAL_IMAGE" == "$EXPECTED_IMAGE" ]] || fail "Expected image '$EXPECTED_IMAGE' but found '$ACTUAL_IMAGE'"
pass "Deployment uses correct image: $EXPECTED_IMAGE"

# 7) Check if deployment has correct number of replicas
ACTUAL_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$ACTUAL_REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Expected $EXPECTED_REPLICAS replicas but found $ACTUAL_REPLICAS"
pass "Deployment has correct replica count: $EXPECTED_REPLICAS"

# 8) Check if deployment has selector (required for apps/v1)
SELECTOR=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null)
[[ -n "$SELECTOR" ]] || fail "Deployment missing required 'selector.matchLabels' field for apps/v1"
pass "Deployment has required selector field"

# 9) Check if deployment is ready
echo "Waiting for deployment to be ready..."
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become ready within timeout"

# 10) Check if pods are running
READY_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "$READY_REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Expected $EXPECTED_REPLICAS ready pods but found ${READY_REPLICAS:-0}"
pass "All $EXPECTED_REPLICAS pods are ready and running"

# 11) Verify pods are actually running
RUNNING_PODS=$(kubectl -n "$NS" get pods -l app=web-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
[[ "$RUNNING_PODS" -ge "$EXPECTED_REPLICAS" ]] || fail "Expected at least $EXPECTED_REPLICAS running pods but found $RUNNING_PODS"
pass "Verified $RUNNING_PODS pods are in Running state"

echo ""
echo "================================================"
pass "All verification checks passed!"
echo "================================================"
echo ""
echo "Summary:"
echo "  ✓ kubectl-convert plugin installed"
echo "  ✓ Deprecated APIs fixed (apps/v1beta1 → apps/v1)"
echo "  ✓ Required selector field added"
echo "  ✓ Deployment created in '$NS' namespace"
echo "  ✓ All $EXPECTED_REPLICAS pods are running successfully"

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

# 0) kubectl-convert plugin is installed
if ! kubectl convert --help >/dev/null 2>&1; then
  fail "kubectl-convert plugin is not installed. Please install it before proceeding."
fi
pass "kubectl-convert plugin is installed"

# 1) Manifest file exists
[[ -f "$MANIFEST" ]] || fail "Manifest file not found at $MANIFEST"
pass "Manifest file exists at $MANIFEST"

# 2) The file ON DISK must be the fixed one — not just applied from a
#    separate copy. This is checked independently of the live Deployment,
#    so getting this step right matters even if your deployment already works.
if grep -q "apps/v1beta" "$MANIFEST" 2>/dev/null || grep -q "extensions/v1beta1" "$MANIFEST" 2>/dev/null; then
  fail "The manifest at $MANIFEST still contains a deprecated apiVersion. If your Deployment is already running, you likely applied a separately-converted file — the task requires overwriting $MANIFEST itself with the fixed version."
fi
pass "No deprecated API versions found in the manifest file"

if grep -q "rollbackTo" "$MANIFEST" 2>/dev/null; then
  fail "The manifest at $MANIFEST still contains 'rollbackTo', a field removed in apps/v1. Re-run kubectl-convert and make sure you save its output back over $MANIFEST."
fi
pass "No leftover deprecated fields (rollbackTo) found in the manifest file"

if ! grep -q "apiVersion: apps/v1$" "$MANIFEST" 2>/dev/null; then
  fail "Manifest should use 'apiVersion: apps/v1' for the Deployment."
fi
pass "Manifest file uses apiVersion: apps/v1"

# 3) Namespace exists
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found. Did you create it?"
pass "Namespace '$NS' exists"

# 4) Deployment exists in viper namespace
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'"
pass "Deployment '$DEP' exists in namespace '$NS'"

# 5) Correct image
ACTUAL_IMAGE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$ACTUAL_IMAGE" == "$EXPECTED_IMAGE" ]] || fail "Expected image '$EXPECTED_IMAGE' but found '$ACTUAL_IMAGE'"
pass "Deployment uses correct image: $EXPECTED_IMAGE"

# 6) Correct replica count
ACTUAL_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')
[[ "$ACTUAL_REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Expected $EXPECTED_REPLICAS replicas but found $ACTUAL_REPLICAS"
pass "Deployment has correct replica count: $EXPECTED_REPLICAS"

# 7) selector present (required for apps/v1)
SELECTOR=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null)
[[ -n "$SELECTOR" ]] || fail "Deployment missing required 'selector.matchLabels' field for apps/v1"
pass "Deployment has required selector field"

# 8) Deployment is ready
echo "Waiting for deployment to be ready..."
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 \
  || fail "Deployment '$DEP' did not become ready within timeout"

READY_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
[[ "$READY_REPLICAS" == "$EXPECTED_REPLICAS" ]] || fail "Expected $EXPECTED_REPLICAS ready pods but found ${READY_REPLICAS:-0}"
pass "All $EXPECTED_REPLICAS pods are ready and running"

# 9) Pods actually running
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
echo "  ✓ Manifest file on disk fixed (apps/v1, rollbackTo removed)"
echo "  ✓ Required selector field added"
echo "  ✓ Deployment created in '$NS' namespace"
echo "  ✓ All $EXPECTED_REPLICAS pods are running successfully"

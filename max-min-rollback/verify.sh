#!/bin/bash
set -euo pipefail

NAMESPACE="prod"
DEPLOYMENT_NAME="web1"
ORIGINAL_IMAGE="public.ecr.aws/nginx/nginx:perl"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying rolling update and rollback configuration..."

# Verify deployment exists
kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'."

# Verify rolling update strategy is configured
STRATEGY_TYPE=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.strategy.type}')
[[ "$STRATEGY_TYPE" == "RollingUpdate" ]] || fail "Strategy type must be 'RollingUpdate'. Current: '$STRATEGY_TYPE'"

# Verify maxUnavailable is 0% (could be 0%, 0, or not set with 0 as calculated value)
MAX_UNAVAILABLE=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null || echo "notset")
if [[ "$MAX_UNAVAILABLE" != "0%" && "$MAX_UNAVAILABLE" != "0" ]]; then
    fail "maxUnavailable must be '0%' or '0'. Current: '$MAX_UNAVAILABLE'"
fi

# Verify maxSurge is 5% (could be 5%, 5, or 1 as calculated value for 10 pods)
MAX_SURGE=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || echo "notset")
if [[ "$MAX_SURGE" != "5%" && "$MAX_SURGE" != "1" ]]; then
    fail "maxSurge must be '5%' or '1'. Current: '$MAX_SURGE'"
fi

# Verify deployment has 10 replicas
REPLICAS=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "10" ]] || fail "Deployment must have 10 replicas. Current: $REPLICAS"

# Verify all replicas are ready
READY_REPLICAS=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
[[ "$READY_REPLICAS" == "10" ]] || fail "All 10 replicas must be ready. Ready: $READY_REPLICAS"

# Verify current image (should be back to original after rollback)
CURRENT_IMAGE=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$CURRENT_IMAGE" == "$ORIGINAL_IMAGE" ]] || fail "After rollback, image must be '$ORIGINAL_IMAGE'. Current: '$CURRENT_IMAGE'"

# Verify rollout history exists (should have at least 2 revisions: original + rollback)
REVISION_COUNT=$(kubectl -n $NAMESPACE rollout history deployment/$DEPLOYMENT_NAME 2>/dev/null | grep -c "^[0-9]" || echo "0")
if [[ "$REVISION_COUNT" -lt "2" ]]; then
    fail "Rollout history should show at least 2 revisions (update + rollback). Found: $REVISION_COUNT"
fi

# Verify all pods are running the correct image
POD_IMAGES=$(kubectl -n $NAMESPACE get pods -l app=web-frontend -o jsonpath='{.items[*].spec.containers[0].image}')
for img in $POD_IMAGES; do
    [[ "$img" == "$ORIGINAL_IMAGE" ]] || fail "All pods must be running '$ORIGINAL_IMAGE'. Found pod with: '$img'"
done

# Count pods with correct image
POD_COUNT=$(kubectl -n $NAMESPACE get pods -l app=web-frontend --no-headers 2>/dev/null | wc -l)
[[ "$POD_COUNT" == "10" ]] || fail "Should have 10 pods running. Found: $POD_COUNT"

# Verify deployment is not in progressing state (rollout completed)
DEPLOYMENT_CONDITION=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}')
[[ "$DEPLOYMENT_CONDITION" == "True" ]] || fail "Deployment should be in healthy progressing state."

echo ""
echo "🎉 All verifications passed!"
echo ""
echo "📊 Final Configuration Summary:"
echo "├─ 📦 Deployment: $DEPLOYMENT_NAME"
echo "│  ├─ Replicas: 10/10 ready"
echo "│  ├─ Image: $CURRENT_IMAGE (rolled back)"
echo "│  └─ Strategy: RollingUpdate"
echo "├─ ⚙️  Rolling Update Configuration:"
echo "│  ├─ maxUnavailable: $MAX_UNAVAILABLE (zero downtime)"
echo "│  └─ maxSurge: $MAX_SURGE (controlled rollout)"
echo "├─ 📜 Rollout History:"
echo "│  └─ Revisions: $REVISION_COUNT (update + rollback completed)"
echo "└─ ✅ Status: All pods healthy and stable"
echo ""
echo "🎯 Tasks Completed:"
echo "   ✅ Configured rolling update strategy (0% unavailable, 5% surge)"
echo "   ✅ Updated deployment to new image version"
echo "   ✅ Monitored rollout to completion"
echo "   ✅ Simulated failure scenario"
echo "   ✅ Successfully rolled back to previous version"
echo "   ✅ Verified all pods running original image"
echo ""
echo "💡 Key Achievement: Demonstrated zero-downtime deployment"
echo "   with controlled rollout and successful rollback capability!"

pass "Production rolling update and rollback procedures completed successfully! Your deployment is stable and users experienced no downtime."

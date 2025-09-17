#!/bin/bash
set -euo pipefail

NAMESPACE="team-alpha-production"
DEPLOYMENT_NAME="backend-api-service"
QUOTA_NAME="team-alpha-quota"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying resource quota compliance for Team Alpha..."

# Verify namespace exists
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || fail "Namespace '$NAMESPACE' does not exist."

# Verify resource quota exists
kubectl -n $NAMESPACE get resourcequota $QUOTA_NAME >/dev/null 2>&1 || fail "ResourceQuota '$QUOTA_NAME' not found in namespace '$NAMESPACE'."

# Get quota memory limit
QUOTA_MEMORY_LIMIT=$(kubectl -n $NAMESPACE get resourcequota $QUOTA_NAME -o jsonpath='{.spec.hard.requests\.memory}' 2>/dev/null || true)
[[ -n "$QUOTA_MEMORY_LIMIT" ]] || fail "Could not retrieve memory quota limit from ResourceQuota."

echo "📊 Namespace Memory Quota: $QUOTA_MEMORY_LIMIT"

# Convert quota to bytes for calculation (handle Gi suffix)
QUOTA_BYTES=0
if [[ "$QUOTA_MEMORY_LIMIT" =~ ^([0-9]+)Gi$ ]]; then
    QUOTA_GI=${BASH_REMATCH[1]}
    QUOTA_BYTES=$((QUOTA_GI * 1024 * 1024 * 1024))
elif [[ "$QUOTA_MEMORY_LIMIT" =~ ^([0-9]+)Mi$ ]]; then
    QUOTA_MI=${BASH_REMATCH[1]}
    QUOTA_BYTES=$((QUOTA_MI * 1024 * 1024))
else
    fail "Unsupported memory quota format: $QUOTA_MEMORY_LIMIT"
fi

# Calculate expected memory request (50% of quota)
EXPECTED_TOTAL_BYTES=$((QUOTA_BYTES / 2))
EXPECTED_TOTAL_GI=$((EXPECTED_TOTAL_BYTES / 1024 / 1024 / 1024))

echo "📐 Expected Total Memory Request (50% of quota): ${EXPECTED_TOTAL_GI}Gi"

# Verify deployment exists
kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'."

# Get current replica count
REPLICA_COUNT=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.replicas}')
echo "🔄 Current Replica Count: $REPLICA_COUNT"

# Calculate expected memory per pod
EXPECTED_PER_POD_GI=$((EXPECTED_TOTAL_GI / REPLICA_COUNT))
echo "🧮 Expected Memory per Pod: ${EXPECTED_PER_POD_GI}Gi"

# Verify deployment has memory requests configured
MEMORY_REQUEST=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
[[ -n "$MEMORY_REQUEST" ]] || fail "Deployment '$DEPLOYMENT_NAME' does not have memory requests configured. Please add memory requests to the container spec."

echo "💾 Configured Memory Request per Pod: $MEMORY_REQUEST"

# Verify memory request matches expected value
EXPECTED_REQUEST="${EXPECTED_PER_POD_GI}Gi"
[[ "$MEMORY_REQUEST" == "$EXPECTED_REQUEST" ]] || fail "Memory request '$MEMORY_REQUEST' does not match expected value '$EXPECTED_REQUEST' (50% of quota divided by replica count)."

# Verify pods are running with correct resources
READY_REPLICAS=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
[[ "$READY_REPLICAS" == "$REPLICA_COUNT" ]] || fail "Not all replicas are ready. Expected: $REPLICA_COUNT, Ready: $READY_REPLICAS"

# Check resource quota usage
QUOTA_USED_MEMORY=$(kubectl -n $NAMESPACE get resourcequota $QUOTA_NAME -o jsonpath='{.status.used.requests\.memory}' 2>/dev/null || echo "0")
echo "📈 Current Quota Usage: $QUOTA_USED_MEMORY"

# Verify quota usage matches expected
if [[ "$QUOTA_USED_MEMORY" != "${EXPECTED_TOTAL_GI}Gi" ]]; then
    echo "⚠️  Note: Quota usage ($QUOTA_USED_MEMORY) may take a moment to reflect the deployment changes."
fi

# Additional verification: Check actual pod resource specifications
echo ""
echo "🔍 Pod Resource Verification:"
POD_COUNT=$(kubectl -n $NAMESPACE get pods -l app=backend-api --no-headers | wc -l)
[[ "$POD_COUNT" == "$REPLICA_COUNT" ]] || fail "Expected $REPLICA_COUNT pods, found $POD_COUNT"

# Verify each pod has correct memory request
PODS_WITH_MEMORY=$(kubectl -n $NAMESPACE get pods -l app=backend-api -o jsonpath='{.items[*].spec.containers[0].resources.requests.memory}' | tr ' ' '\n' | grep -c "${EXPECTED_PER_POD_GI}Gi" || echo "0")
[[ "$PODS_WITH_MEMORY" == "$REPLICA_COUNT" ]] || fail "Not all pods have correct memory requests. Expected $REPLICA_COUNT pods with ${EXPECTED_PER_POD_GI}Gi, found $PODS_WITH_MEMORY"

echo ""
echo "📊 Resource Quota Compliance Summary:"
echo "├─ 🎯 Namespace: $NAMESPACE"
echo "├─ 📋 Quota Limit: $QUOTA_MEMORY_LIMIT"
echo "├─ 🧮 Required Request (50%): ${EXPECTED_TOTAL_GI}Gi"
echo "├─ 🚀 Deployment: $DEPLOYMENT_NAME"
echo "├─ 🔄 Replicas: $REPLICA_COUNT"
echo "├─ 💾 Memory per Pod: ${EXPECTED_PER_POD_GI}Gi"
echo "├─ ✅ Configuration: Compliant"
echo "└─ 📈 Quota Usage: $QUOTA_USED_MEMORY / $QUOTA_MEMORY_LIMIT"

# Final quota status
echo ""
echo "🎉 Final Resource Quota Status:"
kubectl -n $NAMESPACE describe resourcequota $QUOTA_NAME | grep -E "(requests.memory|limits.memory)"

pass "Deployment successfully configured with memory requests at 50% of namespace quota! Team Alpha's resource governance compliance achieved."

#!/bin/bash
set -euo pipefail

NAMESPACE="project-one"
POD_NAME="nginx-resources"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying Project One resource configuration..."

# Verify namespace exists
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || fail "Namespace '$NAMESPACE' does not exist. Please create it with: kubectl create namespace $NAMESPACE"

# Verify pod exists
kubectl -n $NAMESPACE get pod $POD_NAME >/dev/null 2>&1 || fail "Pod '$POD_NAME' not found in namespace '$NAMESPACE'."

# Verify pod is using nginx image
POD_IMAGE=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.containers[0].image}')
[[ "$POD_IMAGE" == "nginx" ]] || fail "Pod must use 'nginx' image. Current image: '$POD_IMAGE'"

# Verify CPU request
CPU_REQUEST=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)
[[ "$CPU_REQUEST" == "200m" ]] || fail "Pod must have CPU request of '200m'. Current CPU request: '$CPU_REQUEST'"

# Verify memory request
MEMORY_REQUEST=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
[[ "$MEMORY_REQUEST" == "1Gi" ]] || fail "Pod must have memory request of '1Gi'. Current memory request: '$MEMORY_REQUEST'"

# Verify pod is running or at least scheduled
POD_PHASE=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.status.phase}')
if [[ "$POD_PHASE" == "Pending" ]]; then
    # Check if it's pending due to resource constraints
    PENDING_REASON=$(kubectl -n $NAMESPACE describe pod $POD_NAME | grep -A 5 "Events:" | grep "Insufficient" || true)
    if [[ -n "$PENDING_REASON" ]]; then
        fail "Pod is pending due to insufficient cluster resources. This is expected behavior when requests exceed available capacity."
    else
        echo "⏳ Pod is pending but not due to resource constraints (likely still starting up)"
    fi
elif [[ "$POD_PHASE" != "Running" && "$POD_PHASE" != "Succeeded" ]]; then
    echo "⚠️  Pod phase is '$POD_PHASE' - checking for issues..."
    kubectl -n $NAMESPACE describe pod $POD_NAME | tail -10
fi

# Verify container name (should be nginx or the container name)
CONTAINER_NAME=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.containers[0].name}')
echo "📦 Container name: $CONTAINER_NAME"

# Check if pod has been assigned to a node
NODE_NAME=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.nodeName}' 2>/dev/null || true)
if [[ -n "$NODE_NAME" ]]; then
    echo "🖥️  Pod scheduled on node: $NODE_NAME"
else
    echo "⏳ Pod not yet scheduled to a node"
fi

# Display resource configuration
echo ""
echo "📊 Resource Configuration Verified:"
echo "├─ 📦 Pod: $POD_NAME"
echo "├─ 🌐 Namespace: $NAMESPACE"
echo "├─ 🖼️  Image: nginx"
echo "├─ ⚡ CPU Request: 200m"
echo "├─ 🧠 Memory Request: 1Gi"
echo "└─ 📍 Status: $POD_PHASE"

# Show actual resource requests from pod spec
echo ""
echo "🔍 Detailed Resource Specification:"
kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.spec.containers[0].resources}' | python3 -m json.tool 2>/dev/null || kubectl -n $NAMESPACE describe pod $POD_NAME | grep -A 3 "Requests:"

# Check node capacity if pod is scheduled
if [[ -n "$NODE_NAME" ]]; then
    echo ""
    echo "🖥️  Node Resource Capacity:"
    kubectl describe node $NODE_NAME | grep -A 5 "Allocatable:" || true
fi

pass "Project One nginx pod successfully configured with required resource requests! The pod guarantees 200m CPU and 1Gi memory allocation."

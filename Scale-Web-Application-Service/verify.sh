#!/bin/bash
set -euo pipefail

NAMESPACE="ecommerce-platform"
DEPLOYMENT_NAME="ecommerce-frontend-deployment"
SERVICE_NAME="ecommerce-frontend-service"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying e-commerce platform configuration..."

# Verify deployment exists
kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'."

# Verify deployment has 5 replicas
REPLICAS=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.replicas}')
[[ "$REPLICAS" == "5" ]] || fail "Deployment must have 5 replicas. Current replicas: $REPLICAS"

# Verify deployment has the required label in pod template
ROLE_LABEL=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.template.metadata.labels.role}' 2>/dev/null || true)
[[ "$ROLE_LABEL" == "webfrontend" ]] || fail "Pod template must have label 'role: webfrontend'. Current role label: '$ROLE_LABEL'"

# Verify all replicas are ready
READY_REPLICAS=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
[[ "$READY_REPLICAS" == "5" ]] || fail "All 5 replicas must be ready. Ready replicas: $READY_REPLICAS"

# Verify service exists
kubectl -n $NAMESPACE get service $SERVICE_NAME >/dev/null 2>&1 || fail "Service '$SERVICE_NAME' not found in namespace '$NAMESPACE'."

# Verify service type is NodePort
SERVICE_TYPE=$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.type}')
[[ "$SERVICE_TYPE" == "NodePort" ]] || fail "Service type must be 'NodePort'. Current type: '$SERVICE_TYPE'"

# Verify service port is 8000
SERVICE_PORT=$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.ports[0].port}')
[[ "$SERVICE_PORT" == "8000" ]] || fail "Service must expose port 8000. Current port: $SERVICE_PORT"

# Verify target port is 80
TARGET_PORT=$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.ports[0].targetPort}')
[[ "$TARGET_PORT" == "80" ]] || fail "Service target port must be 80. Current target port: $TARGET_PORT"

# Verify service selector matches deployment labels
SERVICE_SELECTOR=$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.selector.app}')
DEPLOYMENT_LABEL=$(kubectl -n $NAMESPACE get deployment $DEPLOYMENT_NAME -o jsonpath='{.spec.template.metadata.labels.app}')
[[ "$SERVICE_SELECTOR" == "$DEPLOYMENT_LABEL" ]] || fail "Service selector (app=$SERVICE_SELECTOR) must match deployment pod labels (app=$DEPLOYMENT_LABEL)."

# Verify service has endpoints
ENDPOINTS_COUNT=$(kubectl -n $NAMESPACE get endpoints $SERVICE_NAME -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
[[ "$ENDPOINTS_COUNT" == "5" ]] || fail "Service should have 5 endpoints (one per pod). Found: $ENDPOINTS_COUNT"

# Additional verification: Check if pods have both required labels
PODS_WITH_APP_LABEL=$(kubectl -n $NAMESPACE get pods -l app=ecommerce-frontend --no-headers | wc -l)
[[ "$PODS_WITH_APP_LABEL" == "5" ]] || fail "Should have 5 pods with 'app=ecommerce-frontend' label. Found: $PODS_WITH_APP_LABEL"

PODS_WITH_ROLE_LABEL=$(kubectl -n $NAMESPACE get pods -l role=webfrontend --no-headers | wc -l)
[[ "$PODS_WITH_ROLE_LABEL" == "5" ]] || fail "Should have 5 pods with 'role=webfrontend' label. Found: $PODS_WITH_ROLE_LABEL"

# Get NodePort for final output
NODE_PORT=$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "🎉 All verifications passed!"
echo ""
echo "📊 Final Configuration Summary:"
echo "├─ 📦 Deployment: $DEPLOYMENT_NAME"
echo "│  ├─ Replicas: 5/5 ready"
echo "│  ├─ Pod Labels: app=ecommerce-frontend, role=webfrontend"
echo "│  └─ Container Port: 80"
echo "├─ 🌐 Service: $SERVICE_NAME"
echo "│  ├─ Type: NodePort"
echo "│  ├─ Port: 8000 → 80"
echo "│  ├─ NodePort: $NODE_PORT"
echo "│  └─ Endpoints: 5 pods"
echo "└─ ✅ Ready for traffic surge!"
echo ""
echo "🚀 External Access: http://localhost:$NODE_PORT"

pass "E-commerce platform successfully scaled and exposed! The deployment is now ready to handle the product launch traffic."

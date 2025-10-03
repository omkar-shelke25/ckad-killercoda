#!/bin/bash
set -euo pipefail

NS="galaxy"
DEP="warp-core"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 0) Namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

# 1) Deployment exists
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."
pass "Deployment '$DEP' exists in namespace '$NS'"

# 2) Check readinessProbe configuration
echo "🔍 Checking readinessProbe configuration..."

READINESS_PATH=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')
READINESS_PORT=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')
READINESS_INITIAL=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds}')
READINESS_PERIOD=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.periodSeconds}')

[[ -n "$READINESS_PATH" ]] || fail "readinessProbe is not configured."
[[ "$READINESS_PATH" == "/helathz" ]] || fail "readinessProbe path must be '/helathz' (found '$READINESS_PATH')."
[[ "$READINESS_PORT" == "80" ]] || fail "readinessProbe port must be 80 (found '$READINESS_PORT')."
[[ "$READINESS_INITIAL" == "2" ]] || fail "readinessProbe initialDelaySeconds must be 2 (found '$READINESS_INITIAL')."
[[ "$READINESS_PERIOD" == "5" ]] || fail "readinessProbe periodSeconds must be 5 (found '$READINESS_PERIOD')."
pass "readinessProbe configured correctly: path=/helathz, port=80, initialDelay=2s, period=5s"

# 3) Check livenessProbe configuration
echo "🔍 Checking livenessProbe configuration..."

LIVENESS_PATH=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}')
LIVENESS_PORT=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}')
LIVENESS_INITIAL=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.initialDelaySeconds}')
LIVENESS_PERIOD=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.periodSeconds}')
LIVENESS_FAILURE=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.failureThreshold}')

[[ -n "$LIVENESS_PATH" ]] || fail "livenessProbe is not configured."
[[ "$LIVENESS_PATH" == "/helathz" ]] || fail "livenessProbe path must be '/helathz' (found '$LIVENESS_PATH')."
[[ "$LIVENESS_PORT" == "80" ]] || fail "livenessProbe port must be 80 (found '$LIVENESS_PORT')."
[[ "$LIVENESS_INITIAL" == "5" ]] || fail "livenessProbe initialDelaySeconds must be 5 (found '$LIVENESS_INITIAL')."
[[ "$LIVENESS_PERIOD" == "10" ]] || fail "livenessProbe periodSeconds must be 10 (found '$LIVENESS_PERIOD')."
[[ "$LIVENESS_FAILURE" == "3" ]] || fail "livenessProbe failureThreshold must be 3 (found '$LIVENESS_FAILURE')."
pass "livenessProbe configured correctly: path=/helathz, port=80, initialDelay=5s, period=10s, failureThreshold=3"

# 4) Check deployment status
echo "⏳ Checking deployment and pod status..."

READY_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl -n "$NS" get deploy "$DEP" -o jsonpath='{.spec.replicas}')

[[ -n "$READY_REPLICAS" ]] || fail "No ready replicas found. Deployment may not be healthy."
[[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]] || fail "Expected $DESIRED_REPLICAS ready replicas, found $READY_REPLICAS."
pass "Deployment has $READY_REPLICAS/$DESIRED_REPLICAS ready replicas"

# 5) Check pod readiness with probes
RUNNING_PODS=$(kubectl -n "$NS" get pods -l app="warp-core" --field-selector=status.phase=Running -o json | jq '.items | length')
READY_PODS=$(kubectl -n "$NS" get pods -l app="warp-core" --field-selector=status.phase=Running -o json | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')

[[ "$RUNNING_PODS" -gt 0 ]] || fail "No running pods found for deployment '$DEP'."
[[ "$READY_PODS" == "$RUNNING_PODS" ]] || fail "Not all pods are ready. Running: $RUNNING_PODS, Ready: $READY_PODS. Check probe configurations."
pass "All pods are running and ready: $READY_PODS/$RUNNING_PODS"

# 6) Verify probes are actually being executed (check pod status)
echo "🔍 Verifying probe execution on pods..."
POD_NAME=$(kubectl -n "$NS" get pods -l app="warp-core" -o jsonpath='{.items[0].metadata.name}')

if [[ -n "$POD_NAME" ]]; then
    CONTAINER_READY=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.status.containerStatuses[0].ready}')
    [[ "$CONTAINER_READY" == "true" ]] || fail "Container in pod '$POD_NAME' is not ready. Probes may be failing."
    pass "Probes are executing successfully on pod '$POD_NAME'"
fi

# 7) Check ConfigMap exists
kubectl -n "$NS" get configmap warp-core-pages >/dev/null 2>&1 || fail "ConfigMap 'warp-core-pages' not found."
pass "ConfigMap 'warp-core-pages' exists with health check data"

echo ""
pass "🎉 Verification successful! Warp Core probe systems are operational:"
echo "   ✓ Namespace: $NS"
echo "   ✓ Deployment: $DEP"
echo "   ✓ readinessProbe: HTTP GET /helathz:80 (initial=2s, period=5s)"
echo "   ✓ livenessProbe: HTTP GET /helathz:80 (initial=5s, period=10s, failure=3)"
echo "   ✓ Status: $READY_PODS pods ready and healthy"
echo "   ✓ Health monitoring: Active and functional"

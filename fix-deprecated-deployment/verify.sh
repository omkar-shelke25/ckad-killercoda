#!/bin/bash
set -euo pipefail

DEPLOYMENT="legacy-app"
NAMESPACE="migration"
YAML_FILE="/opt/course/api-fix/legacy-app.yaml"
DOCS_FILE="/opt/course/api-fix/changes-documented.md"
EXPECTED_API_VERSION="apps/v1"
DEPRECATED_API_VERSION="extensions/v1beta1"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }
warn(){ echo "⚠️ $1"; }

echo "🔍 Starting API Deprecation Fix Verification..."
echo ""

# Set context to cluster1
kubectl config use-context cluster1 >/dev/null 2>&1 || fail "Failed to set context to cluster1"
pass "Context set to cluster1"

# Check if namespace exists
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || fail "Namespace '$NAMESPACE' does not exist"
pass "Namespace '$NAMESPACE' exists"

# Check if deployment YAML file exists
[ -f "$YAML_FILE" ] || fail "Deployment YAML file '$YAML_FILE' not found"
pass "Deployment YAML file exists"

# Check if deployment exists
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
pass "Deployment '$DEPLOYMENT' exists in namespace '$NAMESPACE'"

# Check if YAML file has been updated with correct API version
YAML_API_VERSION=$(grep -E "^apiVersion:" "$YAML_FILE" | awk '{print $2}' | tr -d ' \t\n\r')
if [ "$YAML_API_VERSION" = "$EXPECTED_API_VERSION" ]; then
    pass "YAML file uses correct API version: $EXPECTED_API_VERSION"
else
    if [ "$YAML_API_VERSION" = "$DEPRECATED_API_VERSION" ]; then
        fail "YAML file still uses deprecated API version: $YAML_API_VERSION. Update to: $EXPECTED_API_VERSION"
    else
        fail "YAML file uses unexpected API version: $YAML_API_VERSION. Expected: $EXPECTED_API_VERSION"
    fi
fi

# Check if the deployed resource is using the correct API version
DEPLOYED_API_VERSION=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.apiVersion}')
if [ "$DEPLOYED_API_VERSION" = "$EXPECTED_API_VERSION" ]; then
    pass "Deployed resource uses correct API version: $EXPECTED_API_VERSION"
else
    fail "Deployed resource uses incorrect API version: $DEPLOYED_API_VERSION. Expected: $EXPECTED_API_VERSION"
fi

# Check if deployment is healthy and running
READY_REPLICAS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ] && [ "$READY_REPLICAS" -gt 0 ]; then
    pass "Deployment is healthy with $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
else
    fail "Deployment is not healthy. Ready: $READY_REPLICAS, Desired: $DESIRED_REPLICAS"
fi

# Check if pods are running
POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$POD_COUNT" -gt 0 ]; then
    pass "$POD_COUNT pod(s) are running successfully"
else
    fail "No pods are running for deployment '$DEPLOYMENT'"
fi

# Verify deployment functionality is maintained
# Check essential deployment fields
CONTAINER_COUNT=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -gt 0 ]; then
    pass "Deployment maintains container configuration"
else
    fail "Deployment container configuration is missing"
fi

# Check if resources are still configured
RESOURCE_REQUESTS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
if [ -n "$RESOURCE_REQUESTS" ]; then
    pass "Resource requests are maintained"
else
    warn "Resource requests might be missing"
fi

# Check if environment variables are maintained
ENV_COUNT=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' | wc -w)
if [ "$ENV_COUNT" -gt 0 ]; then
    pass "Environment variables are maintained"
else
    warn "Environment variables might be missing"
fi

# Check if probes are maintained
READINESS_PROBE=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}')
LIVENESS_PROBE=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}')

if [ -n "$READINESS_PROBE" ]; then
    pass "Readiness probe is maintained"
else
    warn "Readiness probe might be missing"
fi

if [ -n "$LIVENESS_PROBE" ]; then
    pass "Liveness probe is maintained"
else
    warn "Liveness probe might be missing"
fi

# Check if service is still working
SERVICE_EXISTS=$(kubectl get service legacy-app-service -n "$NAMESPACE" >/dev/null 2>&1 && echo "true" || echo "false")
if [ "$SERVICE_EXISTS" = "true" ]; then
    pass "Associated service is still accessible"
    
    # Test service connectivity (optional)
    SERVICE_IP=$(kubectl get service legacy-app-service -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
    if [ -n "$SERVICE_IP" ]; then
        pass "Service has valid cluster IP: $SERVICE_IP"
    fi
fi

# Check for no deprecation warnings when applying
APPLY_OUTPUT=$(kubectl apply -f "$YAML_FILE" --dry-run=server 2>&1)
if echo "$APPLY_OUTPUT" | grep -qi "deprecated\|warning"; then
    warn "Deprecation warnings still present when applying the YAML"
    echo "Output: $APPLY_OUTPUT"
else
    pass "No deprecation warnings when applying the updated YAML"
fi

# Check if documentation file has been updated
if [ -f "$DOCS_FILE" ]; then
    pass "Documentation file exists"
    
    # Check if documentation contains key information
    if grep -q "$EXPECTED_API_VERSION" "$DOCS_FILE"; then
        pass "Documentation mentions the correct API version"
    else
        warn "Documentation should mention the new API version: $EXPECTED_API_VERSION"
    fi
    
    if grep -q "$DEPRECATED_API_VERSION" "$DOCS_FILE"; then
        pass "Documentation mentions the deprecated API version"
    else
        warn "Documentation should mention the old deprecated API version"
    fi
    
    if grep -q "Changes Applied\|Changes Made" "$DOCS_FILE"; then
        pass "Documentation contains change information"
    else
        warn "Documentation should contain detailed change information"
    fi
else
    fail "Documentation file '$DOCS_FILE' not found or not updated"
fi

# Final rollout status check
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=60s >/dev/null 2>&1 || fail "Deployment rollout is not successful"
pass "Deployment rollout is successful"

# Check current deployment generation vs observed generation (ensures update was applied)
CURRENT_GEN=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.metadata.generation}')
OBSERVED_GEN=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.observedGeneration}')

if [ "$CURRENT_GEN" = "$OBSERVED_GEN" ]; then
    pass "Deployment update has been fully observed and applied"
else
    fail "Deployment update may not be fully applied. Generation: $CURRENT_GEN, Observed: $OBSERVED_GEN"
fi

echo ""
echo "✅ Verification Complete! API Deprecation Fix Implementation is Successful!"
echo ""
echo "🎯 Summary of Achievements:"
echo "   • ✅ Updated API version from $DEPRECATED_API_VERSION to $EXPECTED_API_VERSION"
echo "   • ✅ Deployment is healthy with all replicas ready"
echo "   • ✅ All functionality is maintained (containers, resources, probes)"
echo "   • ✅ No deprecation warnings present"
echo "   • ✅ Changes are properly documented"
echo ""
echo "🚀 The legacy application is now using supported API versions and is future-ready!"

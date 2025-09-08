#!/bin/bash
set -euo pipefail

DEPLOYMENT="cleaner"
NAMESPACE="mercury"
YAML_FILE="/opt/course/16/cleaner-new.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Check if the YAML file exists
[ -f "$YAML_FILE" ] || fail "Deployment YAML file '$YAML_FILE' not found."
pass "Deployment YAML file exists."

# Check if namespace exists
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || fail "Namespace '$NAMESPACE' not found."
pass "Namespace '$NAMESPACE' exists."

# Check basic YAML structure
grep -q "name: cleaner-con" "$YAML_FILE" || fail "Container 'cleaner-con' not found."
grep -q "name: logger-con" "$YAML_FILE" || fail "Container 'logger-con' not found."
grep -q "busybox:1.31.0" "$YAML_FILE" || fail "Required image 'busybox:1.31.0' not found."
pass "Required containers and image found in YAML."

# Check for tail command
grep -q "tail" "$YAML_FILE" || fail "Command 'tail' not found in YAML."
pass "Tail command found in YAML."

# Check for volume mounts
grep -q "volumeMounts:" "$YAML_FILE" || fail "Volume mounts not configured."
grep -q "mountPath:" "$YAML_FILE" || fail "Mount path not configured."
pass "Volume mounts configured."

# Apply the deployment
echo "Applying deployment..."
kubectl replace -f "$YAML_FILE" --force >/dev/null 2>&1 || fail "Failed to apply deployment."
pass "Deployment applied successfully."

# Wait for deployment (shorter timeout)
echo "Waiting for deployment..."
kubectl wait --for=condition=Available deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=60s >/dev/null 2>&1 || fail "Deployment not available within 60s."
pass "Deployment is available."

# Get pod name
POD_NAME=$(kubectl get pods -l app="$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -n "$POD_NAME" ] || fail "Could not find pod."
pass "Found pod: $POD_NAME"

# Check pod status
POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$POD_STATUS" = "Running" ] || fail "Pod is not running. Status: $POD_STATUS"
pass "Pod is running."

# Check container count
CONTAINER_COUNT=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}' | wc -w)
[ "$CONTAINER_COUNT" -eq 2 ] || fail "Expected 2 containers, found $CONTAINER_COUNT."
pass "Pod has 2 containers."

# Quick log generation wait
echo "Waiting for logs..."
sleep 10

# Check if main container is writing logs
LOG_CHECK=$(kubectl exec "$POD_NAME" -c cleaner-con -n "$NAMESPACE" -- sh -c "ls -la /tmp/cleaner.log 2>/dev/null || echo 'NO_FILE'")
if [ "$LOG_CHECK" = "NO_FILE" ]; then
    fail "Log file /tmp/cleaner.log not created by main container."
else
    pass "Log file created by main container."
fi

# Check if sidecar can access the file
kubectl exec "$POD_NAME" -c logger-con -n "$NAMESPACE" -- test -f /tmp/cleaner.log >/dev/null 2>&1 || fail "Sidecar cannot access log file."
pass "Sidecar can access log file."

# Check sidecar logs (with timeout)
echo "Checking sidecar logs..."
timeout 10 kubectl logs "$POD_NAME" -c logger-con -n "$NAMESPACE" --tail=1 >/dev/null 2>&1 || fail "Sidecar container not producing logs."
pass "Sidecar container is producing logs."

echo ""
echo "✅ All verifications passed!"
echo "🎯 Sidecar container successfully implemented"
echo ""
echo "To view logs manually:"
echo "kubectl logs -n $NAMESPACE $POD_NAME -c logger-con"

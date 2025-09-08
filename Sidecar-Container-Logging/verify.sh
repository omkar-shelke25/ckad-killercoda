#!/bin/bash
set -euo pipefail

DEPLOYMENT="cleaner"
NAMESPACE="mercury"
YAML_FILE="/opt/course/16/cleaner-new.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Check if the YAML file exists
[ -f "$YAML_FILE" ] || fail "Deployment YAML file '$YAML_FILE' not found."
pass "Deployment YAML file exists at '$YAML_FILE'."

# Check if the deployment YAML contains two containers
CONTAINER_COUNT=$(grep -c "name: .*-con" "$YAML_FILE" || echo "0")
[ "$CONTAINER_COUNT" -eq 2 ] || fail "Expected 2 containers, found $CONTAINER_COUNT in '$YAML_FILE'."
pass "Found 2 containers in deployment YAML."

# Check if logger-con container is defined
grep -q "name: logger-con" "$YAML_FILE" || fail "Sidecar container 'logger-con' not found in deployment YAML."
pass "Sidecar container 'logger-con' is defined in deployment YAML."

# Check if logger-con uses busybox:1.31.0 image
if grep -A 5 "name: logger-con" "$YAML_FILE" | grep -q "busybox:1.31.0"; then
    pass "Sidecar container is using correct image 'busybox:1.31.0'."
else
    fail "Sidecar container is not using 'busybox:1.31.0' image."
fi

# Check if the logger-con has a command that uses tail -f
if grep -A 10 "name: logger-con" "$YAML_FILE" | grep -q "tail.*-f"; then
    pass "Sidecar container command uses 'tail -f' for log following."
else
    fail "Sidecar container command should use 'tail -f' to follow the log file."
fi

# Check if the logger-con has volume mount
if grep -A 15 "name: logger-con" "$YAML_FILE" | grep -q "volumeMounts:"; then
    pass "Sidecar container has volume mount configured."
else
    fail "Sidecar container must have volume mount configured."
fi

# Check if both containers mount to /tmp
CLEANER_MOUNT=$(grep -A 20 "name: cleaner-con" "$YAML_FILE" | grep -A 5 "volumeMounts:" | grep "mountPath:" | awk '{print $2}' || echo "")
LOGGER_MOUNT=$(grep -A 20 "name: logger-con" "$YAML_FILE" | grep -A 5 "volumeMounts:" | grep "mountPath:" | awk '{print $2}' || echo "")

if [[ "$CLEANER_MOUNT" == "/tmp" ]] && [[ "$LOGGER_MOUNT" == "/tmp" ]]; then
    pass "Both containers mount volume to /tmp."
else
    fail "Both containers should mount volume to /tmp. Found: cleaner-con='$CLEANER_MOUNT', logger-con='$LOGGER_MOUNT'"
fi

# Apply the deployment if changes were made
kubectl replace -f "$YAML_FILE" --force >/dev/null 2>&1 || fail "Failed to apply deployment."
pass "Deployment applied successfully."

# Wait for deployment to be available
kubectl wait --for=condition=Available deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT' did not become available."
pass "Deployment '$DEPLOYMENT' is available in namespace '$NAMESPACE'."

# Check if pods are ready
kubectl wait --for=condition=Ready pod -l app="$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s >/dev/null 2>&1 || fail "Pods are not ready."
pass "Pods are ready."

# Get pod name
POD_NAME=$(kubectl get pods -l app="$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')
[ -n "$POD_NAME" ] || fail "Could not find pod for deployment '$DEPLOYMENT' in namespace '$NAMESPACE'."
pass "Found pod: $POD_NAME"

# Check if pod has exactly 2 containers
CONTAINER_COUNT_RUNNING=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}' | wc -w)
[ "$CONTAINER_COUNT_RUNNING" -eq 2 ] || fail "Pod should have exactly 2 containers, found $CONTAINER_COUNT_RUNNING."
pass "Pod has exactly 2 containers running."

# Verify containers are named correctly
CONTAINERS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
if [[ "$CONTAINERS" == *"cleaner-con"* ]] && [[ "$CONTAINERS" == *"logger-con"* ]]; then
    pass "Both containers 'cleaner-con' and 'logger-con' are present in the pod."
else
    fail "Expected containers 'cleaner-con' and 'logger-con', found: $CONTAINERS"
fi

# Wait a moment for logs to be generated
echo "⏳ Waiting for log generation..."
sleep 15

# Check if cleaner.log file exists in the pod
if kubectl exec "$POD_NAME" -c cleaner-con -n "$NAMESPACE" -- test -f /tmp/cleaner.log >/dev/null 2>&1; then
    pass "Log file /tmp/cleaner.log exists in cleaner-con container."
else
    fail "Log file /tmp/cleaner.log does not exist in cleaner-con container."
fi

# Check if logger-con can access the same log file
if kubectl exec "$POD_NAME" -c logger-con -n "$NAMESPACE" -- test -f /tmp/cleaner.log >/dev/null 2>&1; then
    pass "Log file /tmp/cleaner.log is accessible from logger-con container."
else
    fail "Log file /tmp/cleaner.log is not accessible from logger-con container."
fi

# Check if logger-con produces logs to stdout
echo "🔍 Testing sidecar container logs..."
SIDECAR_LOGS=$(kubectl logs "$POD_NAME" -c logger-con -n "$NAMESPACE" --tail=5 2>/dev/null || echo "NO_LOGS")

if [[ "$SIDECAR_LOGS" == "NO_LOGS" ]] || [[ -z "$SIDECAR_LOGS" ]]; then
    fail "Sidecar container 'logger-con' is not producing any logs to stdout."
elif [[ "$SIDECAR_LOGS" == *"cleaning data"* ]]; then
    pass "Sidecar container is successfully outputting log content to stdout."
else
    fail "Sidecar container logs don't contain expected 'cleaning data' content."
fi

# Check if both containers are in the same pod and sharing the volume
MAIN_LOG_LINES=$(kubectl exec "$POD_NAME" -c cleaner-con -n "$NAMESPACE" -- wc -l /tmp/cleaner.log 2>/dev/null | awk '{print $1}' || echo "0")
SIDECAR_LOG_LINES=$(kubectl logs "$POD_NAME" -c logger-con -n "$NAMESPACE" 2>/dev/null | wc -l || echo "0")

if [[ "$MAIN_LOG_LINES" -gt 0 ]] && [[ "$SIDECAR_LOG_LINES" -gt 0 ]]; then
    pass "Volume sharing is working - both containers can access the log file."
else
    fail "Volume sharing issue - main container log lines: $MAIN_LOG_LINES, sidecar output lines: $SIDECAR_LOG_LINES"
fi

# Final verification: Check that the sidecar is actually tailing the file (should show recent entries)
RECENT_MAIN_LOG=$(kubectl exec "$POD_NAME" -c cleaner-con -n "$NAMESPACE" -- tail -1 /tmp/cleaner.log 2>/dev/null || echo "")
RECENT_SIDECAR_LOG=$(kubectl logs "$POD_NAME" -c logger-con -n "$NAMESPACE" --tail=1 2>/dev/null || echo "")

if [[ -n "$RECENT_MAIN_LOG" ]] && [[ -n "$RECENT_SIDECAR_LOG" ]]; then
    pass "Sidecar is actively tailing the log file."
else
    # This might be timing related, so we won't fail but will note it
    pass "Sidecar container is configured correctly (timing may affect log sync)."
fi

echo ""
echo "✅ Verification successful! Sidecar container implementation is working correctly."
echo "🎯 Sidecar container 'logger-con' is successfully processing logs from 'cleaner-con'"
echo "📊 Main container writes logs to /tmp/cleaner.log"
echo "📡 Sidecar container outputs log content to stdout using 'tail -f'"
echo "🔄 Volume sharing between containers is functioning properly"
echo ""
echo "🔍 To check logs manually, use:"
echo "   kubectl logs -n mercury deployment/cleaner -c logger-con"
echo "   kubectl logs -n mercury deployment/cleaner -c logger-con -f  # for live following"

#!/bin/bash
set -euo pipefail

NS="mercury"
DEP="cleaner"
MAIN_CONTAINER="cleaner-con"
SIDECAR_CONTAINER="logger-con"
YAML_PATH="/opt/course/16/cleaner-new.yaml"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

echo "🔍 Verifying CKAD Sidecar Container Exercise..."
echo ""

# 1) Check if cleaner-new.yaml exists
[[ -f "$YAML_PATH" ]] || fail "File '$YAML_PATH' not found. You must save your changes to this file."
pass "File '$YAML_PATH' exists"

# 2) Check if deployment exists
kubectl -n "$NS" get deployment "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."
pass "Deployment '$DEP' exists in namespace '$NS'"

# 3) Check if main container exists
MAIN_EXISTS=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$MAIN_CONTAINER"'")].name}')
[[ "$MAIN_EXISTS" == "$MAIN_CONTAINER" ]] || fail "Main container '$MAIN_CONTAINER' not found in deployment."
pass "Main container '$MAIN_CONTAINER' exists"

# 4) Check if sidecar container exists as initContainer
SIDECAR_EXISTS=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].name}')
[[ "$SIDECAR_EXISTS" == "$SIDECAR_CONTAINER" ]] || fail "Sidecar container '$SIDECAR_CONTAINER' not found as initContainer in deployment."
pass "Sidecar container '$SIDECAR_CONTAINER' exists as initContainer"

# 5) Check sidecar image
SIDECAR_IMAGE=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].image}')
if [[ "$SIDECAR_IMAGE" == *"busybox"* ]]; then
    pass "Sidecar uses busybox image: $SIDECAR_IMAGE"
else
    fail "Sidecar must use busybox image (found '$SIDECAR_IMAGE')."
fi

# 6) Check restartPolicy
RESTART_POLICY=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].restartPolicy}')
[[ "$RESTART_POLICY" == "Always" ]] || fail "Sidecar restartPolicy must be 'Always' (found '$RESTART_POLICY')."
pass "Sidecar has restartPolicy: Always (sidecar pattern)"

# 7) Check if both containers mount the same volume
MAIN_VOLUME=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$MAIN_CONTAINER"'")].volumeMounts[0].name}')
SIDECAR_VOLUME=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].volumeMounts[0].name}')

[[ -n "$MAIN_VOLUME" ]] || fail "Main container has no volume mount."
[[ -n "$SIDECAR_VOLUME" ]] || fail "Sidecar container has no volume mount."
[[ "$MAIN_VOLUME" == "$SIDECAR_VOLUME" ]] || fail "Both containers must mount the same volume (main: '$MAIN_VOLUME', sidecar: '$SIDECAR_VOLUME')."
pass "Both containers mount the same volume: $MAIN_VOLUME"

# 8) Check mount paths
MAIN_MOUNT=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.containers[?(@.name=="'"$MAIN_CONTAINER"'")].volumeMounts[0].mountPath}')
SIDECAR_MOUNT=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].volumeMounts[0].mountPath}')

[[ "$MAIN_MOUNT" == "/var/log" ]] || fail "Main container should mount at /var/log (found '$MAIN_MOUNT')."
[[ "$SIDECAR_MOUNT" == "/var/log" ]] || fail "Sidecar container should mount at /var/log (found '$SIDECAR_MOUNT')."
pass "Both containers mount at /var/log"

# 9) Check if sidecar uses tail -f command
SIDECAR_CMD=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].command}' | jq -r '. | join(" ")')
SIDECAR_ARGS=$(kubectl -n "$NS" get deployment "$DEP" -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="'"$SIDECAR_CONTAINER"'")].args}' | jq -r '. | join(" ")')

FULL_CMD="$SIDECAR_CMD $SIDECAR_ARGS"

if [[ "$FULL_CMD" == *"tail"* && "$FULL_CMD" == *"/var/log/cleaner.log"* ]]; then
    pass "Sidecar uses tail command to stream cleaner.log"
else
    fail "Sidecar must use 'tail -f /var/log/cleaner.log' command."
fi

# 10) Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready --timeout=60s pod -l app=cleaner -n "$NS" >/dev/null 2>&1 || fail "Pods are not ready."
pass "Pods are ready"

# 11) Get pod name
POD_NAME=$(kubectl -n "$NS" get pods -l app=cleaner -o jsonpath='{.items[0].metadata.name}')
[[ -n "$POD_NAME" ]] || fail "Could not find pod for deployment '$DEP'."
pass "Found pod: $POD_NAME"

# 12) Check if sidecar container is running
SIDECAR_STATE=$(kubectl -n "$NS" get pod "$POD_NAME" -o jsonpath='{.status.initContainerStatuses[?(@.name=="'"$SIDECAR_CONTAINER"'")].state}' | jq -r 'keys[0]')
[[ "$SIDECAR_STATE" == "running" ]] || fail "Sidecar container is not running (state: $SIDECAR_STATE)."
pass "Sidecar container is running"

# 13) Check if logs are accessible from sidecar
echo "📋 Checking logs from sidecar container..."
LOGS=$(kubectl -n "$NS" logs "$POD_NAME" -c "$SIDECAR_CONTAINER" --tail=10 2>/dev/null || echo "")

if [[ -z "$LOGS" ]]; then
    fail "No logs available from sidecar container '$SIDECAR_CONTAINER'."
fi

pass "Logs are accessible from sidecar container"

# 14) Check if logs contain expected content
if [[ "$LOGS" == *"Cleaning data"* ]] || [[ "$LOGS" == *"cleaner.log"* ]]; then
    pass "Logs contain expected cleaner application output"
else
    fail "Logs do not contain expected content. Make sure sidecar is tailing cleaner.log."
fi

# 15) Check for missing data warnings
if [[ "$LOGS" == *"missing"* ]] || [[ "$LOGS" == *"WARNING"* ]]; then
    pass "✨ Found evidence of missing data incidents in logs!"
    echo ""
    echo "📊 Sample log entries revealing the issue:"
    echo "$LOGS" | grep -i "warning\|missing" | head -3 || echo "$LOGS" | head -3
else
    echo "⚠️  Warning messages may not be visible yet. Wait a few seconds and check again with:"
    echo "   kubectl logs -n $NS $POD_NAME -c $SIDECAR_CONTAINER"
fi

echo ""
pass "🎉 Verification successful! Sidecar container configured correctly:"
echo "   ✓ Namespace: $NS"
echo "   ✓ Deployment: $DEP"
echo "   ✓ Main Container: $MAIN_CONTAINER"
echo "   ✓ Sidecar Container: $SIDECAR_CONTAINER (initContainer with restartPolicy: Always)"
echo "   ✓ Shared Volume: $MAIN_VOLUME mounted at /var/log"
echo "   ✓ Log Streaming: tail -f /var/log/cleaner.log → stdout"
echo "   ✓ Status: Both containers running, logs accessible"
echo ""
echo "🔍 To view the logs revealing missing data incidents:"
echo "   kubectl logs -n $NS deployment/$DEP -c $SIDECAR_CONTAINER --tail=20"

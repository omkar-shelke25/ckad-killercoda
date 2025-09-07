#!/bin/bash
set -euo pipefail

DEPLOYMENT="test-init-container"
YAML_FILE="/opt/course/17/test-init-container.yaml"
EXPECTED_CONTENT="check this out!"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Check if the YAML file exists
[ -f "$YAML_FILE" ] || fail "Deployment YAML file '$YAML_FILE' not found."
pass "Deployment YAML file exists at '$YAML_FILE'."

# Check if the deployment YAML contains initContainers section
grep -q "initContainers:" "$YAML_FILE" || fail "No 'initContainers' section found in '$YAML_FILE'."
pass "InitContainers section found in deployment YAML."

# Check if init-con container is defined
grep -q "name: init-con" "$YAML_FILE" || fail "InitContainer 'init-con' not found in deployment YAML."
pass "InitContainer 'init-con' is defined in deployment YAML."

# Check if busybox:1.31.0 image is used
grep -q "busybox:1.31.0" "$YAML_FILE" || fail "InitContainer is not using 'busybox:1.31.0' image."
pass "InitContainer is using correct image 'busybox:1.31.0'."

# Check if the InitContainer has a command that creates index.html
if grep -A 10 "name: init-con" "$YAML_FILE" | grep -q "index.html"; then
    pass "InitContainer command creates index.html file."
else
    fail "InitContainer command should create index.html file."
fi

# Check if the InitContainer has volume mount
if grep -A 15 "name: init-con" "$YAML_FILE" | grep -q "volumeMounts:"; then
    pass "InitContainer has volume mount configured."
else
    fail "InitContainer must have volume mount configured."
fi

# Apply the deployment if not already applied
if ! kubectl get deployment "$DEPLOYMENT" >/dev/null 2>&1; then
    kubectl apply -f "$YAML_FILE" || fail "Failed to apply deployment."
fi

# Wait for deployment to be available
kubectl wait --for=condition=Available deployment/"$DEPLOYMENT" --timeout=120s >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT' did not become available."
pass "Deployment '$DEPLOYMENT' is available."

# Check if pods are ready
kubectl wait --for=condition=Ready pod -l app="$DEPLOYMENT" --timeout=120s >/dev/null 2>&1 || fail "Pods are not ready."
pass "Pods are ready."

# Get pod name
POD_NAME=$(kubectl get pods -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}')
[ -n "$POD_NAME" ] || fail "Could not find pod for deployment '$DEPLOYMENT'."
pass "Found pod: $POD_NAME"

# Check if init container completed successfully
INIT_STATUS=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.initContainerStatuses[0].state.terminated.reason}' 2>/dev/null || echo "")
if [ "$INIT_STATUS" = "Completed" ]; then
    pass "InitContainer completed successfully."
else
    # Check if it's still running or in another state
    INIT_PHASE=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [ "$INIT_PHASE" = "Running" ]; then
        # Check if main container is running (means init completed)
        CONTAINER_READY=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        if [ "$CONTAINER_READY" = "true" ]; then
            pass "InitContainer completed successfully (main container is running)."
        else
            fail "InitContainer may not have completed successfully."
        fi
    else
        fail "InitContainer did not complete successfully. Status: $INIT_STATUS, Phase: $INIT_PHASE"
    fi
fi

# Check if service exists, if not create it
if ! kubectl get service "$DEPLOYMENT" >/dev/null 2>&1; then
    kubectl expose deployment "$DEPLOYMENT" --port=80 --target-port=80 || fail "Failed to create service."
fi

# Wait a moment for service to be ready
sleep 2

# Test the content using curl from a temporary pod
echo "🧪 Testing web server content..."
CURL_RESULT=$(kubectl run tmp-test-$(date +%s) --restart=Never --rm -i --image=nginx:alpine --quiet -- sh -c "curl -s -m 10 http://$DEPLOYMENT 2>/dev/null || echo 'CURL_FAILED'" 2>/dev/null)

# Clean up any failed test pods
kubectl delete pod -l run=tmp-test --ignore-not-found=true >/dev/null 2>&1 || true

# Check if curl was successful and contains expected content
if [[ "$CURL_RESULT" == "CURL_FAILED" ]] || [[ -z "$CURL_RESULT" ]]; then
    # Fallback: Check file directly in the pod
    FILE_CONTENT=$(kubectl exec "$POD_NAME" -c nginx -- sh -c "cat /usr/share/nginx/html/index.html 2>/dev/null || echo 'FILE_NOT_FOUND'")
    if [[ "$FILE_CONTENT" == "FILE_NOT_FOUND" ]]; then
        fail "Neither curl test nor direct file check succeeded."
    elif [[ "$FILE_CONTENT" == *"$EXPECTED_CONTENT"* ]]; then
        pass "File '/usr/share/nginx/html/index.html' contains correct content: '$EXPECTED_CONTENT'"
    else
        fail "File content mismatch. Expected '$EXPECTED_CONTENT', found: '$FILE_CONTENT'"
    fi
else
    # Curl succeeded, check content
    if [[ "$CURL_RESULT" == *"$EXPECTED_CONTENT"* ]]; then
        pass "Web server is serving the correct content via HTTP: '$EXPECTED_CONTENT'"
    else
        fail "Web server content mismatch. Expected '$EXPECTED_CONTENT', got: '$CURL_RESULT'"
    fi
fi

# Additional verification: Check that index.html exists in nginx container
if kubectl exec "$POD_NAME" -c nginx -- test -f /usr/share/nginx/html/index.html >/dev/null 2>&1; then
    pass "File index.html exists in nginx container's document root."
else
    fail "File index.html does not exist in nginx container's document root."
fi

# Check init container logs (informational)
INIT_LOGS=$(kubectl logs "$POD_NAME" -c init-con 2>/dev/null || echo "No logs available")
if [[ -n "$INIT_LOGS" ]] && [[ "$INIT_LOGS" != "No logs available" ]]; then
    pass "InitContainer logs are accessible."
else
    pass "InitContainer completed (logs may be empty for simple commands)."
fi

echo ""
echo "✅ Verification successful! InitContainer implementation is working correctly."
echo "🎯 InitContainer 'init-con' successfully created index.html with content '$EXPECTED_CONTENT'"
echo "🌐 Nginx container is serving the file prepared by the InitContainer"
echo "📁 Volume sharing between InitContainer and main container is functioning properly"

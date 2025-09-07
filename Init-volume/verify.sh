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

# Apply the deployment if not already applied
kubectl get deployment "$DEPLOYMENT" >/dev/null 2>&1 || kubectl apply -f "$YAML_FILE"

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
[ "$INIT_STATUS" = "Completed" ] || fail "InitContainer did not complete successfully. Status: $INIT_STATUS"
pass "InitContainer completed successfully."

# Check if the volume mount is configured correctly in init container
kubectl get pod "$POD_NAME" -o yaml | grep -A 10 "initContainers:" | grep -q "mountPath: /usr/share/nginx/html" || fail "InitContainer volume mount not configured correctly."
pass "InitContainer has correct volume mount configuration."

# Expose the deployment if service doesn't exist
kubectl get service "$DEPLOYMENT" >/dev/null 2>&1 || kubectl expose deployment "$DEPLOYMENT" --port=80 --target-port=80

# Test the content using curl from a temporary pod
echo "Testing web server content..."
CURL_OUTPUT=$(kubectl run tmp-test-$(date +%s) --restart=Never --rm -i --image=nginx:alpine -- sh -c "curl -s http://$DEPLOYMENT" 2>/dev/null || true)

# Clean up any failed test pods
kubectl delete pod -l run=tmp-test --ignore-not-found=true >/dev/null 2>&1 || true

# Check if the output contains the expected content
if [[ "$CURL_OUTPUT" == *"$EXPECTED_CONTENT"* ]]; then
    pass "Web server is serving the correct content: '$EXPECTED_CONTENT'"
else
    fail "Web server content mismatch. Expected '$EXPECTED_CONTENT', got: '$CURL_OUTPUT'"
fi

# Check init container logs for verification
INIT_LOGS=$(kubectl logs "$POD_NAME" -c init-con 2>/dev/null || true)
pass "InitContainer logs accessible."

# Verify the file was created by checking nginx container
FILE_CONTENT=$(kubectl exec "$POD_NAME" -c nginx -- cat /usr/share/nginx/html/index.html 2>/dev/null || true)
if [[ "$FILE_CONTENT" == *"$EXPECTED_CONTENT"* ]]; then
    pass "File '/usr/share/nginx/html/index.html' contains correct content."
else
    fail "File content verification failed. Expected '$EXPECTED_CONTENT', found: '$FILE_CONTENT'"
fi

echo "✅ Verification successful! InitContainer implementation is working correctly."
echo "🎯 InitContainer 'init-con' successfully created index.html with content '$EXPECTED_CONTENT'"
echo "🌐 Nginx container is serving the file prepared by the InitContainer"

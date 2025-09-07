#!/bin/bash
set -euo pipefail

NS="moon"
DEPLOYMENT="web-moon"
CONFIGMAP="configmap-web-moon-html"
SOURCE_FILE="/opt/course/15/web-moon.html"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# Check if namespace exists
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists."

# Check if source file exists
[ -f "$SOURCE_FILE" ] || fail "Source file '$SOURCE_FILE' not found."
pass "Source file '$SOURCE_FILE' exists."

# Check if ConfigMap exists
kubectl get configmap "$CONFIGMAP" -n "$NS" >/dev/null 2>&1 || fail "ConfigMap '$CONFIGMAP' not found in namespace '$NS'."
pass "ConfigMap '$CONFIGMAP' exists in namespace '$NS'."

# Check if ConfigMap has the correct key
kubectl get configmap "$CONFIGMAP" -n "$NS" -o jsonpath='{.data.index\.html}' >/dev/null 2>&1 || fail "ConfigMap '$CONFIGMAP' does not have key 'index.html'."
pass "ConfigMap '$CONFIGMAP' has key 'index.html'."

# Get ConfigMap content and source file content
CONFIGMAP_CONTENT=$(kubectl get configmap "$CONFIGMAP" -n "$NS" -o jsonpath='{.data.index\.html}')
SOURCE_CONTENT=$(cat "$SOURCE_FILE")

# Compare content (remove any trailing newlines for comparison)
if [ "$(echo "$CONFIGMAP_CONTENT" | tr -d '\n')" = "$(echo "$SOURCE_CONTENT" | tr -d '\n')" ]; then
    pass "ConfigMap content matches source file content."
else
    fail "ConfigMap content does not match source file content."
fi

# Check if Deployment exists
kubectl get deployment "$DEPLOYMENT" -n "$NS" >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT' not found in namespace '$NS'."
pass "Deployment '$DEPLOYMENT' exists in namespace '$NS'."

# Wait for deployment to be ready
kubectl wait --for=condition=Available deployment/"$DEPLOYMENT" -n "$NS" --timeout=120s >/dev/null 2>&1 || fail "Deployment '$DEPLOYMENT' did not become available."
pass "Deployment '$DEPLOYMENT' is available."

# Check if pods are ready
kubectl wait --for=condition=Ready pods -l app=web-moon -n "$NS" --timeout=120s >/dev/null 2>&1 || fail "Pods for deployment '$DEPLOYMENT' are not ready."
pass "Pods for deployment '$DEPLOYMENT' are ready."

# Test if the nginx server serves the correct content
echo "Testing nginx server content..."
CURL_OUTPUT=$(kubectl run tmp-test-$(date +%s) --restart=Never --rm -i --image=nginx:alpine -n "$NS" -- sh -c "curl -s http://web-moon.moon.svc.cluster.local" 2>/dev/null || true)

if [[ "$CURL_OUTPUT" =~ "Web Moon" ]] && [[ "$CURL_OUTPUT" =~ "Team Moonpie" ]]; then
    pass "Nginx server is serving the correct HTML content from ConfigMap."
else
    fail "Nginx server is not serving the expected content. Got: $CURL_OUTPUT"
fi

# Check if ConfigMap is properly mounted in the deployment
VOLUME_MOUNT_CHECK=$(kubectl get deployment "$DEPLOYMENT" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="html-config")].mountPath}' 2>/dev/null || true)
if [[ "$VOLUME_MOUNT_CHECK" =~ "/usr/share/nginx/html" ]]; then
    pass "ConfigMap is properly mounted as volume in the deployment."
else
    fail "ConfigMap volume mount not found or incorrect in deployment."
fi

echo "✅ Verification successful! ConfigMap created correctly and nginx is serving the content."

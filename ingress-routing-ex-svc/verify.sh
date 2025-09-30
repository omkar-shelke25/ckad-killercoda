#!/bin/bash
set -euo pipefail

NS="exam-app"
SERVICE_NAME="external-api"
EXPECTED_EXTERNAL_NAME="httpbin.org"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "Verifying your solution..."
echo ""

# 1) Check if Service exists
kubectl -n "$NS" get svc "$SERVICE_NAME" >/dev/null 2>&1 || fail "Service '$SERVICE_NAME' not found in namespace '$NS'."
pass "Service '$SERVICE_NAME' exists in namespace '$NS'."

# 2) Check if Service type is ExternalName
SERVICE_TYPE=$(kubectl -n "$NS" get svc "$SERVICE_NAME" -o jsonpath='{.spec.type}')
[[ "$SERVICE_TYPE" == "ExternalName" ]] || fail "Service type must be 'ExternalName', but found '$SERVICE_TYPE'."
pass "Service type is ExternalName."

# 3) Check if externalName is set correctly
EXTERNAL_NAME=$(kubectl -n "$NS" get svc "$SERVICE_NAME" -o jsonpath='{.spec.externalName}')
[[ "$EXTERNAL_NAME" == "$EXPECTED_EXTERNAL_NAME" ]] || fail "Service externalName should be '$EXPECTED_EXTERNAL_NAME', but found '$EXTERNAL_NAME'."
pass "Service externalName is correctly set to '$EXPECTED_EXTERNAL_NAME'."

# 4) Check if Ingress exists and points to the Service
INGRESS_NAME="api-ingress"
kubectl -n "$NS" get ingress "$INGRESS_NAME" >/dev/null 2>&1 || fail "Ingress '$INGRESS_NAME' not found."

INGRESS_SERVICE=$(kubectl -n "$NS" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
[[ "$INGRESS_SERVICE" == "$SERVICE_NAME" ]] || fail "Ingress should route to service '$SERVICE_NAME', but routes to '$INGRESS_SERVICE'."
pass "Ingress is correctly configured to route to '$SERVICE_NAME'."

# 5) Test actual HTTP connectivity through the Ingress
echo ""
echo "Testing HTTP connectivity through Ingress..."

# Get the Ingress URL
if [[ -f /tmp/ingress_url.txt ]]; then
  INGRESS_URL=$(cat /tmp/ingress_url.txt)
else
  INGRESS_HTTP_PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
  INGRESS_URL="http://localhost:${INGRESS_HTTP_PORT}/api/"
fi

# Try to access the Ingress endpoint with timeout
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${INGRESS_URL}get" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  pass "Ingress endpoint returns HTTP 200 (success)."
elif [[ "$HTTP_CODE" == "404" ]]; then
  fail "Ingress still returns HTTP 404. The Service may not be configured correctly or needs more time to propagate."
elif [[ "$HTTP_CODE" == "000" ]]; then
  # Connection timeout or failure - check if it's a DNS resolution issue
  echo "⚠️  Connection timeout. Checking Service configuration..."
  
  # Verify the Service configuration once more
  kubectl -n "$NS" get svc "$SERVICE_NAME" -o yaml | grep -A 2 "spec:" | grep "externalName"
  
  fail "Could not connect through Ingress. This might be a DNS resolution issue or the external service is unreachable."
else
  fail "Ingress returned unexpected HTTP code: $HTTP_CODE (expected 200)."
fi

echo ""
echo "🎉 Verification successful!"
echo "   - Service '$SERVICE_NAME' created with type ExternalName"
echo "   - ExternalName points to: $EXPECTED_EXTERNAL_NAME"
echo "   - Ingress successfully routes traffic to external service"
echo "   - HTTP requests return 200 OK (no more 404 errors!)"

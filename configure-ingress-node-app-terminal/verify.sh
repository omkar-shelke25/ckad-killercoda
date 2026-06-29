#!/bin/bash
set -uo pipefail

NAMESPACE="node-app"
INGRESS_NAME="multi-endpoint-ingress"
SERVICE_NAME="multi-endpoint-service"
DOMAIN="node.app.terminal.io"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying Ingress configuration..."
echo ""

# Verify Ingress exists
kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" >/dev/null 2>&1 \
  || fail "Ingress '$INGRESS_NAME' not found in namespace '$NAMESPACE'."

# Verify IngressClassName is nginx
INGRESS_CLASS=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.ingressClassName}' 2>/dev/null || echo "")
[[ "$INGRESS_CLASS" == "nginx" ]] || fail "IngressClassName must be 'nginx'. Current: '$INGRESS_CLASS'"

# Verify Host is configured correctly
INGRESS_HOST=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
[[ "$INGRESS_HOST" == "$DOMAIN" ]] || fail "Ingress host must be '$DOMAIN'. Current: '$INGRESS_HOST'"

# Verify number of paths (should be 2)
PATH_COUNT=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[*].path}' 2>/dev/null | wc -w)
[[ "$PATH_COUNT" -ge "2" ]] || fail "Ingress must have at least 2 paths. Current count: $PATH_COUNT"

# Verify /terminal path exists
TERMINAL_PATH=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/terminal")].path}' 2>/dev/null || echo "")
[[ "$TERMINAL_PATH" == "/terminal" ]] || fail "Path '/terminal' not found in Ingress configuration."

# Verify /app path exists
APP_PATH=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/app")].path}' 2>/dev/null || echo "")
[[ "$APP_PATH" == "/app" ]] || fail "Path '/app' not found in Ingress configuration."

# Verify /terminal PathType is Prefix
TERMINAL_PATHTYPE=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/terminal")].pathType}' 2>/dev/null || echo "")
[[ "$TERMINAL_PATHTYPE" == "Prefix" ]] || fail "PathType for /terminal must be 'Prefix'. Current: '$TERMINAL_PATHTYPE'"

# Verify /app PathType is Prefix
APP_PATHTYPE=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/app")].pathType}' 2>/dev/null || echo "")
[[ "$APP_PATHTYPE" == "Prefix" ]] || fail "PathType for /app must be 'Prefix'. Current: '$APP_PATHTYPE'"

# Verify backend service name for /terminal
TERMINAL_BACKEND=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/terminal")].backend.service.name}' 2>/dev/null || echo "")
[[ "$TERMINAL_BACKEND" == "$SERVICE_NAME" ]] || fail "Backend service for /terminal must be '$SERVICE_NAME'. Current: '$TERMINAL_BACKEND'"

# Verify backend service name for /app
APP_BACKEND=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/app")].backend.service.name}' 2>/dev/null || echo "")
[[ "$APP_BACKEND" == "$SERVICE_NAME" ]] || fail "Backend service for /app must be '$SERVICE_NAME'. Current: '$APP_BACKEND'"

# Verify backend service port for /terminal
TERMINAL_PORT=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/terminal")].backend.service.port.number}' 2>/dev/null || echo "")
[[ "$TERMINAL_PORT" == "80" ]] || fail "Backend service port for /terminal must be 80. Current: '$TERMINAL_PORT'"

# Verify backend service port for /app
APP_PORT=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/app")].backend.service.port.number}' 2>/dev/null || echo "")
[[ "$APP_PORT" == "80" ]] || fail "Backend service port for /app must be 80. Current: '$APP_PORT'"

# Verify service exists
kubectl -n "$NAMESPACE" get service "$SERVICE_NAME" >/dev/null 2>&1 \
  || fail "Service '$SERVICE_NAME' not found."

# Capture the service's actual type (used later in the summary — never hardcode this)
SERVICE_TYPE=$(kubectl -n "$NAMESPACE" get service "$SERVICE_NAME" -o jsonpath='{.spec.type}' 2>/dev/null || echo "Unknown")

# Verify the service has endpoints.
# NOTE: the previous version used {.subsets[0].addresses[*].ip}, which throws an
# "array index out of bounds" error from kubectl (and kills the whole script under
# `set -e`, with no friendly message) when there are zero subsets — e.g. pods not
# Ready yet. Using `range` avoids indexing into a possibly-empty array entirely.
ENDPOINTS=$(kubectl -n "$NAMESPACE" get endpoints "$SERVICE_NAME" \
  -o jsonpath='{range .subsets[*]}{range .addresses[*]}{.ip}{"\n"}{end}{end}' 2>/dev/null \
  | grep -c . || true)
ENDPOINTS=${ENDPOINTS:-0}
[[ "$ENDPOINTS" -ge "1" ]] || fail "Service '$SERVICE_NAME' has no endpoints. Check if pods are running: kubectl -n $NAMESPACE get pods -l app=multi-endpoint"

# Get Ingress Controller's external IP (from its Service, via MetalLB)
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
[[ -n "$INGRESS_IP" ]] || fail "Ingress Controller has no external IP assigned. Check MetalLB configuration."

# Verify the Ingress resource itself has picked up an address too (this is what
# Part 2 of the task actually asks you to confirm — it should match $INGRESS_IP
# once the nginx ingress controller publishes its status).
INGRESS_RESOURCE_IP=$(kubectl -n "$NAMESPACE" get ingress "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
[[ -n "$INGRESS_RESOURCE_IP" ]] || fail "Ingress '$INGRESS_NAME' has not obtained an address yet. Wait a bit and check: kubectl -n $NAMESPACE get ingress $INGRESS_NAME"

# Verify /etc/hosts entry
grep -q "$DOMAIN" /etc/hosts \
  || fail "DNS entry for '$DOMAIN' not found in /etc/hosts. Add it with: echo '$INGRESS_IP $DOMAIN' | sudo tee -a /etc/hosts"

echo "🌐 Testing HTTP access to endpoints..."
echo ""

# Test /terminal endpoint
echo "Testing /terminal endpoint..."
TERMINAL_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/terminal" --max-time 10 2>/dev/null || echo "000")
[[ "$TERMINAL_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN/terminal failed. HTTP Status: $TERMINAL_HTTP_CODE"

TERMINAL_CONTENT=$(curl -s "http://$DOMAIN/terminal" --max-time 10 2>/dev/null || echo "")
echo "$TERMINAL_CONTENT" | grep -q "Terminal Endpoint" \
  || fail "/terminal response doesn't contain expected 'Terminal Endpoint' content."

echo "✅ /terminal endpoint working correctly (HTTP 200)"
echo ""

# Test /app endpoint
echo "Testing /app endpoint..."
APP_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/app" --max-time 10 2>/dev/null || echo "000")
[[ "$APP_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN/app failed. HTTP Status: $APP_HTTP_CODE"

APP_CONTENT=$(curl -s "http://$DOMAIN/app" --max-time 10 2>/dev/null || echo "")
echo "$APP_CONTENT" | grep -q "Application Dashboard" \
  || fail "/app response doesn't contain expected 'Application Dashboard' content."

echo "✅ /app endpoint working correctly (HTTP 200)"
echo ""

echo "🎉 All verifications passed!"
echo ""
echo "📊 Final Configuration Summary:"
echo "├─ 🌐 Ingress: $INGRESS_NAME"
echo "│  ├─ IngressClass: nginx"
echo "│  ├─ Host: $DOMAIN"
echo "│  ├─ Paths:"
echo "│  │  ├─ /terminal → $SERVICE_NAME:80 (Prefix)"
echo "│  │  └─ /app → $SERVICE_NAME:80 (Prefix)"
echo "│  └─ IP: $INGRESS_RESOURCE_IP"
echo "├─ 🔧 Service: $SERVICE_NAME"
echo "│  ├─ Type: $SERVICE_TYPE"
echo "│  └─ Endpoints: $ENDPOINTS pod(s)"
echo "├─ 🌍 DNS Configuration:"
echo "│  ├─ Domain: $DOMAIN"
echo "│  ├─ IP: $INGRESS_IP"
echo "│  └─ /etc/hosts: Configured ✅"
echo "└─ ✅ HTTP Access:"
echo "   ├─ /terminal endpoint: Working (200 OK)"
echo "   └─ /app endpoint: Working (200 OK)"
echo ""
echo "🚀 Access URLs:"
echo "   • http://$DOMAIN/terminal"
echo "   • http://$DOMAIN/app"
echo ""

pass "Ingress with multiple path routing successfully configured and verified!"

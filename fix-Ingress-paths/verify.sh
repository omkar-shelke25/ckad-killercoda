#!/bin/bash
set -euo pipefail

NAMESPACE="food-app"
INGRESS_NAME="food-app-ingress"
DOMAIN="fast.delivery.io"
NODE_PORT=32080

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying Food Delivery App Configuration..."
echo ""

# ==============================
# Part 1: Verify Payment Service Fix
# ==============================
echo "📦 Part 1: Verifying Payment Service..."

# Check if payment service exists
kubectl -n $NAMESPACE get service payment-service >/dev/null 2>&1 || fail "Service 'payment-service' not found in namespace '$NAMESPACE'."

# Check service selector
SERVICE_SELECTOR=$(kubectl -n $NAMESPACE get service payment-service -o jsonpath='{.spec.selector.app}')
[[ "$SERVICE_SELECTOR" == "payment-service" ]] || fail "Payment service selector must be 'app: payment-service'. Current: 'app: $SERVICE_SELECTOR'. The pods have label 'app=payment-service' but service selector is wrong."

# Check if service has endpoints
PAYMENT_ENDPOINTS=$(kubectl -n $NAMESPACE get endpoints payment-service -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
[[ "$PAYMENT_ENDPOINTS" -ge "1" ]] || fail "Payment service has no endpoints. Fix the service selector to match pod labels."

echo "✅ Payment service selector fixed correctly"
echo "   Selector: app=$SERVICE_SELECTOR"
echo "   Endpoints: $PAYMENT_ENDPOINTS pod(s)"
echo ""

# ==============================
# Part 2: Verify Ingress Configuration
# ==============================
echo "🌐 Part 2: Verifying Ingress Configuration..."

# Check if Ingress exists
kubectl -n $NAMESPACE get ingress $INGRESS_NAME >/dev/null 2>&1 || fail "Ingress '$INGRESS_NAME' not found in namespace '$NAMESPACE'. Apply /app/food-deliver.yaml"

# Verify IngressClassName
INGRESS_CLASS=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.ingressClassName}')
[[ "$INGRESS_CLASS" == "traefik" ]] || fail "IngressClassName must be 'traefik'. Current: '$INGRESS_CLASS'"

# Verify Host
INGRESS_HOST=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].host}')
[[ "$INGRESS_HOST" == "$DOMAIN" ]] || fail "Ingress host must be '$DOMAIN'. Current: '$INGRESS_HOST'"

# Verify number of paths (should be 4)
PATH_COUNT=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[*].path}' | wc -w)
[[ "$PATH_COUNT" -eq "4" ]] || fail "Ingress must have exactly 4 paths. Current count: $PATH_COUNT (Expected: /menu, /order-details, /payment, /track-order)"

# Verify /menu path exists
MENU_PATH=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/menu")].path}')
[[ "$MENU_PATH" == "/menu" ]] || fail "Path '/menu' not found in Ingress configuration."

# Verify /order-details path exists
ORDER_PATH=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/order-details")].path}')
[[ "$ORDER_PATH" == "/order-details" ]] || fail "Path '/order-details' not found in Ingress configuration."

# Verify /payment path exists
PAYMENT_PATH=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/payment")].path}')
[[ "$PAYMENT_PATH" == "/payment" ]] || fail "Path '/payment' not found in Ingress configuration. Add it to /app/food-deliver.yaml"

# Verify /track-order path exists
TRACK_PATH=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/track-order")].path}')
[[ "$TRACK_PATH" == "/track-order" ]] || fail "Path '/track-order' not found in Ingress configuration. Add it to /app/food-deliver.yaml"

# Verify backend service for /menu
MENU_BACKEND=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/menu")].backend.service.name}')
[[ "$MENU_BACKEND" == "menu-service" ]] || fail "Backend service for /menu must be 'menu-service'. Current: '$MENU_BACKEND'"

MENU_PORT=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/menu")].backend.service.port.number}')
[[ "$MENU_PORT" == "8001" ]] || fail "Backend service port for /menu must be 8001. Current: '$MENU_PORT'"

# Verify backend service for /order-details
ORDER_BACKEND=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/order-details")].backend.service.name}')
[[ "$ORDER_BACKEND" == "order-service" ]] || fail "Backend service for /order-details must be 'order-service'. Current: '$ORDER_BACKEND'"

ORDER_PORT=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/order-details")].backend.service.port.number}')
[[ "$ORDER_PORT" == "8002" ]] || fail "Backend service port for /order-details must be 8002. Current: '$ORDER_PORT'"

# Verify backend service for /payment
PAYMENT_BACKEND=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/payment")].backend.service.name}')
[[ "$PAYMENT_BACKEND" == "payment-service" ]] || fail "Backend service for /payment must be 'payment-service'. Current: '$PAYMENT_BACKEND'"

PAYMENT_PORT=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/payment")].backend.service.port.number}')
[[ "$PAYMENT_PORT" == "8003" ]] || fail "Backend service port for /payment must be 8003. Current: '$PAYMENT_PORT'"

# Verify backend service for /track-order
TRACK_BACKEND=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/track-order")].backend.service.name}')
[[ "$TRACK_BACKEND" == "tracking-service" ]] || fail "Backend service for /track-order must be 'tracking-service'. Current: '$TRACK_BACKEND'"

TRACK_PORT=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/track-order")].backend.service.port.number}')
[[ "$TRACK_PORT" == "8004" ]] || fail "Backend service port for /track-order must be 8004. Current: '$TRACK_PORT'"

echo "✅ Ingress configuration is correct"
echo "   IngressClass: $INGRESS_CLASS"
echo "   Host: $INGRESS_HOST"
echo "   Paths: $PATH_COUNT configured"
echo ""

# ==============================
# Part 3: Verify DNS Resolution
# ==============================
echo "🌐 Part 3: Verifying DNS Resolution..."

# Verify /etc/hosts entry
grep -q "$DOMAIN" /etc/hosts || fail "DNS entry for '$DOMAIN' not found in /etc/hosts."

echo "✅ DNS resolution configured"
echo ""

# ==============================
# Part 4: Verify HTTP Access
# ==============================
echo "🌐 Part 4: Testing HTTP Access to All Endpoints..."
echo ""

# Test /menu endpoint
echo "Testing /menu endpoint..."
MENU_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN:$NODE_PORT/menu --max-time 10 2>/dev/null || echo "000")
[[ "$MENU_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN:$NODE_PORT/menu failed. HTTP Status: $MENU_HTTP_CODE"

MENU_CONTENT=$(curl -s http://$DOMAIN:$NODE_PORT/menu --max-time 10 2>/dev/null || echo "")
echo "$MENU_CONTENT" | grep -q "Menu Service" || fail "/menu response doesn't contain expected 'Menu Service' content."
echo "✅ /menu endpoint working (HTTP 200)"

# Test /order-details endpoint
echo "Testing /order-details endpoint..."
ORDER_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN:$NODE_PORT/order-details --max-time 10 2>/dev/null || echo "000")
[[ "$ORDER_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN:$NODE_PORT/order-details failed. HTTP Status: $ORDER_HTTP_CODE"

ORDER_CONTENT=$(curl -s http://$DOMAIN:$NODE_PORT/order-details --max-time 10 2>/dev/null || echo "")
echo "$ORDER_CONTENT" | grep -q "Order Service" || fail "/order-details response doesn't contain expected 'Order Service' content."
echo "✅ /order-details endpoint working (HTTP 200)"

# Test /payment endpoint
echo "Testing /payment endpoint..."
PAYMENT_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN:$NODE_PORT/payment --max-time 10 2>/dev/null || echo "000")
[[ "$PAYMENT_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN:$NODE_PORT/payment failed. HTTP Status: $PAYMENT_HTTP_CODE. Did you fix the payment service selector?"

PAYMENT_CONTENT=$(curl -s http://$DOMAIN:$NODE_PORT/payment --max-time 10 2>/dev/null || echo "")
echo "$PAYMENT_CONTENT" | grep -q "Payment Service" || fail "/payment response doesn't contain expected 'Payment Service' content."
echo "✅ /payment endpoint working (HTTP 200)"

# Test /track-order endpoint
echo "Testing /track-order endpoint..."
TRACK_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN:$NODE_PORT/track-order --max-time 10 2>/dev/null || echo "000")
[[ "$TRACK_HTTP_CODE" == "200" ]] || fail "HTTP request to http://$DOMAIN:$NODE_PORT/track-order failed. HTTP Status: $TRACK_HTTP_CODE"

TRACK_CONTENT=$(curl -s http://$DOMAIN:$NODE_PORT/track-order --max-time 10 2>/dev/null || echo "")
echo "$TRACK_CONTENT" | grep -q "Tracking Service" || fail "/track-order response doesn't contain expected 'Tracking Service' content."
echo "✅ /track-order endpoint working (HTTP 200)"


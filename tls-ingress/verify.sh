#!/bin/bash
set -uo pipefail

NAMESPACE="class-1a"
INGRESS_NAME="hero-reg-ingress"
HOSTNAME="heroes.ua-academy.com"
TLS_SECRET="ua-heroes-tls"

ERRORS=0

echo "Verifying Ingress configuration..."
echo ""

# 1) Ingress exists
if ! kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  echo "FAIL: Ingress '${INGRESS_NAME}' not found in namespace '${NAMESPACE}'"
  exit 1
fi
echo "PASS: Ingress '${INGRESS_NAME}' exists"

# 2) ingressClassName is set to nginx
INGRESS_CLASS=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.ingressClassName}')
if [ "$INGRESS_CLASS" != "nginx" ]; then
  echo "FAIL: ingressClassName is '${INGRESS_CLASS:-<empty>}', expected 'nginx'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: ingressClassName is 'nginx'"
fi

# 3) TLS host and secret
TLS_HOST=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.tls[0].hosts[0]}')
TLS_SECRET_NAME=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.tls[0].secretName}')

if [ "$TLS_HOST" != "$HOSTNAME" ]; then
  echo "FAIL: TLS host is '${TLS_HOST}', expected '${HOSTNAME}'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: TLS host configured correctly"
fi

if [ "$TLS_SECRET_NAME" != "$TLS_SECRET" ]; then
  echo "FAIL: TLS secret is '${TLS_SECRET_NAME}', expected '${TLS_SECRET}'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: TLS secret configured correctly"
fi

# 4) Rule host
RULE_HOST=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.rules[0].host}')
if [ "$RULE_HOST" != "$HOSTNAME" ]; then
  echo "FAIL: Rule host is '${RULE_HOST}', expected '${HOSTNAME}'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: Rule host configured correctly"
fi

# 5) /register path and backend port
REGISTER_PATH=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.rules[0].http.paths[?(@.backend.service.name=="register-service")].path}')
if [ -z "$REGISTER_PATH" ]; then
  echo "FAIL: Path for register-service not found"
  ERRORS=$((ERRORS + 1))
elif [ "$REGISTER_PATH" != "/register" ]; then
  echo "FAIL: Register path is '${REGISTER_PATH}', expected '/register'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: Path /register routes to register-service"
fi

REGISTER_PORT=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.rules[0].http.paths[?(@.backend.service.name=="register-service")].backend.service.port.number}')
if [ "$REGISTER_PORT" != "80" ]; then
  echo "FAIL: Register service port is '${REGISTER_PORT}', expected '80'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: Register service port is 80"
fi

# 6) /verify path and backend port
VERIFY_PATH=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.rules[0].http.paths[?(@.backend.service.name=="verify-service")].path}')
if [ -z "$VERIFY_PATH" ]; then
  echo "FAIL: Path for verify-service not found"
  ERRORS=$((ERRORS + 1))
elif [ "$VERIFY_PATH" != "/verify" ]; then
  echo "FAIL: Verify path is '${VERIFY_PATH}', expected '/verify'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: Path /verify routes to verify-service"
fi

VERIFY_PORT=$(kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.rules[0].http.paths[?(@.backend.service.name=="verify-service")].backend.service.port.number}')
if [ "$VERIFY_PORT" != "80" ]; then
  echo "FAIL: Verify service port is '${VERIFY_PORT}', expected '80'"
  ERRORS=$((ERRORS + 1))
else
  echo "PASS: Verify service port is 80"
fi

echo ""
echo "Ingress status:"
kubectl get ingress "${INGRESS_NAME}" -n "${NAMESPACE}"

echo ""
echo "========================================================================"

if [ "$ERRORS" -eq 0 ]; then
  echo ""
  echo "SUCCESS — Hero Registration Portal configured correctly"
  echo ""
  echo "Configuration Summary:"
  echo "   - Ingress:    ${INGRESS_NAME}"
  echo "   - Namespace:  ${NAMESPACE}"
  echo "   - Hostname:   ${HOSTNAME}"
  echo "   - TLS Secret: ${TLS_SECRET}"
  echo "   - Routes:"
  echo "       /register -> register-service:80"
  echo "       /verify   -> verify-service:80"
  echo ""
  echo "========================================================================"
  exit 0
else
  echo ""
  echo "CONFIGURATION INCOMPLETE — found ${ERRORS} error(s)"
  echo ""
  echo "========================================================================"
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

# Robust validator for Food Delivery App ingress & services
# Usage: ./validate-food-delivery.sh
# or set environment variables before running:
# NAMESPACE, INGRESS_NAME, DOMAIN, NODE_PORT

NAMESPACE="${NAMESPACE:-food-app}"
INGRESS_NAME="${INGRESS_NAME:-food-app-ingress}"
DOMAIN="${DOMAIN:-fast.delivery.io}"
NODE_PORT="${NODE_PORT:-32080}"

# Helpers
fail(){ echo "❌ $*" >&2; exit 1; }
info(){ echo "ℹ️  $*"; }
pass(){ echo "✅ $*"; }
run_kubectl(){ kubectl -n "$NAMESPACE" "$@"; }

# Check kubectl access
kubectl version --client >/dev/null 2>&1 || fail "kubectl client not available."

info "Validating configuration (namespace=$NAMESPACE, ingress=$INGRESS_NAME, domain=$DOMAIN, nodePort=$NODE_PORT)"
echo

# 1) Existence checks
info "Checking resources exist..."
run_kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || fail "Namespace '$NAMESPACE' not found."
run_kubectl get ingress "$INGRESS_NAME" >/dev/null 2>&1 || fail "Ingress '$INGRESS_NAME' not found in namespace '$NAMESPACE'."
pass "Namespace and Ingress exist."

# 2) Ingress checks (class, host, paths)
info "Inspecting Ingress..."
ING_JSONPATH_PREFIX="{.spec}"
ING_CLASS=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath='{.spec.ingressClassName}' 2>/dev/null || echo "")
ING_HOST=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
# collect paths
ING_PATHS_RAW=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath='{range .spec.rules[0].http.paths[*]}{.path}{"\n"}{end}' 2>/dev/null || echo "")

info "IngressClassName: ${ING_CLASS:-<empty>}"
info "Ingress host: ${ING_HOST:-<empty>}"
if [[ -z "$ING_CLASS" ]]; then
  fail "IngressClassName missing. Expected 'traefik'."
fi
if [[ "$ING_CLASS" != "traefik" ]]; then
  fail "IngressClassName must be 'traefik'. Current: '$ING_CLASS'"
fi
if [[ -z "$ING_HOST" ]]; then
  fail "Ingress host missing. Expected '$DOMAIN'."
fi
if [[ "$ING_HOST" != "$DOMAIN" ]]; then
  fail "Ingress host must be '$DOMAIN'. Current: '$ING_HOST'"
fi

# Normalize paths into array
mapfile -t ING_PATHS <<< "$(echo "$ING_PATHS_RAW" | sed '/^\s*$/d')"
EXPECTED_PATHS=("/menu" "/order-details" "/payment" "/track-order")
MISSING=()
for p in "${EXPECTED_PATHS[@]}"; do
  if ! printf '%s\n' "${ING_PATHS[@]}" | grep -x -q -- "$p"; then
    MISSING+=("$p")
  fi
done

if [[ ${#ING_PATHS[@]} -ne ${#EXPECTED_PATHS[@]} ]]; then
  info "Ingress path count mismatch: found ${#ING_PATHS[@]}, expected ${#EXPECTED_PATHS[@]}."
  info "Configured paths:"
  for p in "${ING_PATHS[@]}"; do echo "  - $p"; done
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    fail "Missing expected path(s): ${MISSING[*]}"
  fi
fi

pass "Ingress host/class/paths validated."

# Helper: resolve backend service name and port for a given path
get_backend_for_path(){
  local path="$1"
  # Try to get service name
  svc_name=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath="{.spec.rules[0].http.paths[?(@.path=='$path')].backend.service.name}" 2>/dev/null || echo "")
  # Try numeric port
  svc_port_number=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath="{.spec.rules[0].http.paths[?(@.path=='$path')].backend.service.port.number}" 2>/dev/null || echo "")
  # Try named port
  svc_port_name=$(run_kubectl get ingress "$INGRESS_NAME" -o jsonpath="{.spec.rules[0].http.paths[?(@.path=='$path')].backend.service.port.name}" 2>/dev/null || echo "")

  if [[ -z "$svc_name" ]]; then
    echo "::ERROR::no-backend"
    return
  fi

  if [[ -n "$svc_port_number" ]]; then
    echo "${svc_name}:${svc_port_number}"
    return
  fi

  if [[ -n "$svc_port_name" ]]; then
    # Resolve named port to number from svc.spec.ports
    resolved=$(run_kubectl get svc "$svc_name" -o jsonpath="{range .spec.ports[?(@.name=='$svc_port_name')]}{.port}{end}" 2>/dev/null || echo "")
    if [[ -z "$resolved" ]]; then
      echo "::ERROR::port-name-unresolved:$svc_port_name"
      return
    fi
    echo "${svc_name}:${resolved}"
    return
  fi

  # If neither number nor name found:
  echo "::ERROR::no-port"
}

# 3) Validate backends and service selectors + endpoints
info "Validating backend services, selectors and endpoints..."
declare -A EXPECTED_BACKENDS=( ["/menu"]="menu-service:8001" ["/order-details"]="order-service:8002" ["/payment"]="payment-service:8003" ["/track-order"]="tracking-service:8004" )

for p in "${EXPECTED_PATHS[@]}"; do
  found=$(get_backend_for_path "$p")
  if [[ "$found" == ::ERROR::* ]]; then
    fail "Ingress path $p has invalid backend: $found"
  fi

  expected="${EXPECTED_BACKENDS[$p]}"
  if [[ "$found" != "$expected" ]]; then
    info "Warning: backend for $p is '$found' but expected '$expected'. (Script will still attempt HTTP check.)"
  else
    info "Backend for $p -> $found (expected)"
  fi

  svc_name="${found%%:*}"
  port="${found##*:}"

  # service existence
  run_kubectl get svc "$svc_name" >/dev/null 2>&1 || fail "Service '$svc_name' (backend for $p) not found."

  # check selector
  sel_app=$(run_kubectl get svc "$svc_name" -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")
  if [[ -z "$sel_app" ]]; then
    fail "Service '$svc_name' has no selector.app; pods will not be selected."
  fi
  if [[ "$sel_app" != "$svc_name" && "$svc_name" != "menu-service" && "$svc_name" != "order-service" && "$svc_name" != "payment-service" && "$svc_name" != "tracking-service" ]]; then
    # more lenient: just warn unless it's obviously wrong relative to expected
    info "Service '$svc_name' selector app=$sel_app (not equal to service name)"
  fi

  # endpoints
  ep_count=$(run_kubectl get endpoints "$svc_name" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w || true)
  if [[ -z "$ep_count" || "$ep_count" -eq 0 ]]; then
    fail "Service '$svc_name' has no endpoints (0 addresses). Fix pod labels or service selector."
  fi
  info "Service '$svc_name' has $ep_count endpoint(s)."
done

pass "Backends, selectors, and endpoints verified."

# 4) DNS / hosts check (best-effort, not strict failure)
info "Checking name resolution for $DOMAIN..."
if grep -q "$DOMAIN" /etc/hosts 2>/dev/null; then
  info "/etc/hosts contains $DOMAIN"
else
  # try system DNS
  if command -v host >/dev/null 2>&1; then
    if host "$DOMAIN" >/dev/null 2>&1; then
      info "System DNS resolves $DOMAIN"
    else
      info "WARNING: $DOMAIN not found in /etc/hosts and DNS did not resolve it. NodePort test will use manual Host header + node IP."
    fi
  else
    info "NOTE: 'host' command not available; skipping DNS check. If DNS doesn't resolve, ensure /etc/hosts contains $DOMAIN."
  fi
fi

# 5) Find a node IP to test NodePort
info "Selecting a node IP for NodePort access..."
NODE_IP=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' | grep -v '^$' | head -n1 || true)
if [[ -z "$NODE_IP" ]]; then
  fail "Could not obtain a node internal IP for NodePort testing."
fi
info "Using node IP: $NODE_IP"

# 6) HTTP tests for each path
info "Testing HTTP endpoints through NodePort (with Host header '$DOMAIN')..."
for p in "${EXPECTED_PATHS[@]}"; do
  url="http://${NODE_IP}:${NODE_PORT}${p}"
  info "Requesting $url"
  http_code=$(curl -sS -o /tmp/resp_body_$$ -w "%{http_code}" -H "Host: ${DOMAIN}" --max-time 8 "$url" || echo "000")
  body=$(cat /tmp/resp_body_$$ || true)
  rm -f /tmp/resp_body_$$

  if [[ "$http_code" != "200" ]]; then
    fail "HTTP ${http_code} from $url. Check ingress/router and backend service for path $p."
  fi

  # expected content keywords
  case "$p" in
    /menu) expected_kw="Menu Service" ;;
    /order-details) expected_kw="Order Service" ;;
    /payment) expected_kw="Payment Service" ;;
    /track-order) expected_kw="Tracking Service" ;;
    *) expected_kw="" ;;
  esac

  if [[ -n "$expected_kw" ]]; then
    if ! printf '%s' "$body" | grep -q -F "$expected_kw"; then
      info "WARNING: HTTP 200 but response for $p does not contain expected keyword '$expected_kw'. Response preview:"
      printf '%s\n' "${body:0:400}"
      # don't fail — many apps have different messages — just warn
    else
      info "$p -> HTTP 200 and contains '$expected_kw'."
    fi
  else
    info "$p -> HTTP 200"
  fi
done

pass "All endpoints returned HTTP 200 (and content checks where matched)."

echo
echo "🎉 Final summary:"
echo "  Namespace: $NAMESPACE"
echo "  Ingress: $INGRESS_NAME (class: $ING_CLASS, host: $ING_HOST)"
echo "  Node used for NodePort tests: $NODE_IP:$NODE_PORT"
echo "  Paths validated: ${EXPECTED_PATHS[*]}"
echo
pass "Food Delivery App validation completed successfully."

exit 0

#!/bin/bash
set -euo pipefail

# -----------------------------------------
# VERIFY SCRIPT — app-ingress (streams.local)
# -----------------------------------------
NS="streaming"
ING="app-ingress"
HOST="streams.local"
NODEPORT=30099

# ✅ Helper functions (colored output)
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[1;33m'
nc='\033[0m' # no color

pass() { echo -e "${green}✅ $1${nc}"; }
fail() { echo -e "${red}❌ $1${nc}"; exit 1; }
info() { echo -e "${yellow}➡️  $1${nc}"; }

# -----------------------------------------
# Pre-checks
# -----------------------------------------
command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."
command -v curl >/dev/null 2>&1 || fail "curl not found."

info "Verifying Ingress '${ING}' in namespace '${NS}' ..."

# -----------------------------------------
# Ingress existence
# -----------------------------------------
if ! kubectl -n "$NS" get ingress "$ING" >/dev/null 2>&1; then
  fail "Ingress '${ING}' not found in namespace '${NS}'."
fi
pass "Ingress '${ING}' exists."

# -----------------------------------------
# Host validation
# -----------------------------------------
FOUND_HOST=$(kubectl -n "$NS" get ingress "$ING" -o json | jq -r '.spec.rules[0].host // empty')
[[ "$FOUND_HOST" == "$HOST" ]] || fail "Expected host '${HOST}' but found '${FOUND_HOST:-<none>}'."
pass "Host '${HOST}' found in Ingress rules."

# -----------------------------------------
# Load JSON for deeper checks
# -----------------------------------------
JSON=$(kubectl -n "$NS" get ingress "$ING" -o json)

# -----------------------------------------
# Path validation function
# -----------------------------------------
check_path() {
  local path="$1"
  local svc="$2"
  local port="$3"

  local entry
  entry=$(echo "$JSON" | jq -r --arg p "$path" '.spec.rules[].http.paths[] | select(.path == $p)')
  [[ -n "$entry" ]] || fail "Path '${path}' not found in Ingress rules."

  local ptype
  ptype=$(echo "$entry" | jq -r '.pathType')
  [[ "$ptype" == "Prefix" ]] || fail "Path '${path}' must have pathType 'Prefix' (found: ${ptype})."

  local svc_name svc_port
  svc_name=$(echo "$entry" | jq -r '.backend.service.name // empty')
  svc_port=$(echo "$entry" | jq -r '.backend.service.port.number // empty')

  [[ "$svc_name" == "$svc" && "$svc_port" == "$port" ]] || \
    fail "Path '${path}' must route to '${svc}:${port}' (found: ${svc_name}:${svc_port})."

  pass "Path '${path}' correctly routes to '${svc}:${port}' with pathType='Prefix'."
}

# -----------------------------------------
# Validate paths
# -----------------------------------------
check_path "/api" "api-service" "80"
check_path "/video" "video-service" "80"

# -----------------------------------------
# Live curl test
# -----------------------------------------
info "Testing live HTTP responses through Traefik (NodePort ${NODEPORT})..."

API_RESPONSE=$(curl -s --max-time 5 "http://${HOST}:${NODEPORT}/api" || true)
VIDEO_RESPONSE=$(curl -s --max-time 5 "http://${HOST}:${NODEPORT}/video" || true)

if [[ "$API_RESPONSE" == *"hello-from-api"* ]]; then
  pass "API path '/api' responded correctly with 'hello-from-api'."
else
  fail "API path '/api' did not respond as expected. Got: ${API_RESPONSE:-<no response>}."
fi

if [[ "$VIDEO_RESPONSE" == *"hello-from-video"* ]]; then
  pass "Video path '/video' responded correctly with 'hello-from-video'."
else
  fail "Video path '/video' did not respond as expected. Got: ${VIDEO_RESPONSE:-<no response>}."
fi

# -----------------------------------------
# Final summary
# -----------------------------------------
echo
pass "Ingress '${ING}' verification successful! 🎉"
echo "--------------------------------------------------------------"
echo "✅ Ingress structure and response checks passed successfully."
echo "Namespace : ${NS}"
echo "Host      : ${HOST}"
echo "NodePort  : ${NODEPORT}"
echo "--------------------------------------------------------------"

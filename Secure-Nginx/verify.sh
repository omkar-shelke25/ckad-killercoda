#!/bin/bash
set -euo pipefail

NS="web"
NAME="nginx-web"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

# 1) Namespace
kubectl get ns "${NS}" >/dev/null 2>&1 || fail "Namespace '${NS}' not found."

# 2) Deployment exists
kubectl get deploy "${NAME}" -n "${NS}" >/dev/null 2>&1 || fail "Deployment '${NAME}' not found in namespace '${NS}'."

# Helper for jsonpath
jp() {
  kubectl get deploy "${NAME}" -n "${NS}" -o jsonpath="$1" 2>/dev/null
}

# 3) Replicas = 2
REPLICAS="$(jp '{.spec.replicas}')"
[ "${REPLICAS}" = "2" ] || fail "replicas is '${REPLICAS}', expected '2'."
pass "replicas=2"

# 4) Image
IMAGE="$(jp '{.spec.template.spec.containers[0].image}')"
[ "${IMAGE}" = "nginx:1.25-alpine" ] || fail "image is '${IMAGE}', expected 'nginx:1.25-alpine'."
pass "image=nginx:1.25-alpine"

# 5) Container port 80
PORT="$(jp '{.spec.template.spec.containers[0].ports[0].containerPort}')"
[ "${PORT}" = "80" ] || fail "containerPort is '${PORT}', expected '80'."
pass "containerPort=80"

# 6) runAsUser=101 (accept either Pod or Container level)
POD_RUNAS="$(jp '{.spec.template.spec.securityContext.runAsUser}')"
CTR_RUNAS="$(jp '{.spec.template.spec.containers[0].securityContext.runAsUser}')"
if [ "${POD_RUNAS:-}" = "101" ] || [ "${CTR_RUNAS:-}" = "101" ]; then
  pass "runAsUser=101"
else
  fail "runAsUser is not set to 101 at pod or container level."
fi

# 7) runAsNonRoot=true (accept either Pod or Container level)
POD_NONROOT="$(jp '{.spec.template.spec.securityContext.runAsNonRoot}')"
CTR_NONROOT="$(jp '{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')"
if [ "${POD_NONROOT:-}" = "true" ] || [ "${CTR_NONROOT:-}" = "true" ]; then
  pass "runAsNonRoot=true"
else
  fail "runAsNonRoot is not true at pod or container level."
fi

# 8) allowPrivilegeEscalation=false (must be on container)
APE="$(jp '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')"
[ "${APE}" = "false" ] || fail "allowPrivilegeEscalation is '${APE}', expected 'false'."
pass "allowPrivilegeEscalation=false"

# 9) Capabilities: drop ALL; add NET_BIND_SERVICE (container level)
ADD_CAPS="$(jp '{.spec.template.spec.containers[0].securityContext.capabilities.add[*]}')"
DROP_CAPS="$(jp '{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}')"

echo "${ADD_CAPS}" | grep -qw "NET_BIND_SERVICE" || fail "NET_BIND_SERVICE not present in capabilities.add."
echo "${DROP_CAPS}" | grep -qw "ALL" || fail "ALL not present in capabilities.drop."

# Ensure no extra added caps beyond NET_BIND_SERVICE
EXTRA_ADD="$(echo "${ADD_CAPS}" | tr ' ' '\n' | grep -v '^NET_BIND_SERVICE$' || true)"
[ -z "${EXTRA_ADD}" ] || fail "Unexpected capabilities added: ${EXTRA_ADD}"

pass "capabilities: drop=ALL, add=NET_BIND_SERVICE"

# 10) Pods Ready (rollout)
kubectl -n "${NS}" rollout status deploy/"${NAME}" --timeout=120s >/dev/null 2>&1 || fail "Deployment did not become Ready."
READY="$(kubectl get deploy "${NAME}" -n "${NS}" -o jsonpath='{.status.readyReplicas}')"
[ "${READY}" = "2" ] || fail "Ready replicas is '${READY}', expected '2'."
pass "Deployment Ready with 2/2 replicas."

echo "✅ Verification successful! '${NAME}' in '${NS}' meets all requirements."

#!/bin/bash
set -euo pipefail

NS="net-acm"
DEP="busybox"
CONTAINER_INDEX=0

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# 0) Basic existence
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in namespace '$NS'."

# 1) Check securityContext on container
# Prefer container-level checks; Pod-level is allowed as fallback if container-level unset.
JSON=$(kubectl -n "$NS" get deploy "$DEP" -o json)

# Helper: read json with jq safely
jq -e . >/dev/null 2>&1 || fail "jq not available on the runner."

runAsNonRoot_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.runAsNonRoot // empty")
runAsUser_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.runAsUser // empty")
allowPE_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.allowPrivilegeEscalation // empty")
caps_add_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.capabilities.add // empty")

# Fallback to pod-level if needed
if [[ -z "$runAsNonRoot_container" ]]; then
  runAsNonRoot_pod=$(echo "$JSON" | jq -r ".spec.template.spec.securityContext.runAsNonRoot // empty")
else
  runAsNonRoot_pod=""
fi

if [[ -z "$allowPE_container" ]]; then
  allowPE_pod=$(echo "$JSON" | jq -r ".spec.template.spec.securityContext.allowPrivilegeEscalation // empty")
else
  allowPE_pod=""
fi

# Validate runAsNonRoot (container-level preferred)
if [[ "$runAsNonRoot_container" == "true" ]] || [[ "$runAsNonRoot_pod" == "true" ]]; then
  :
else
  # Accept explicit non-root UID as an alternative
  if [[ -n "$runAsUser_container" ]] && [[ "$runAsUser_container" != "0" ]]; then
    :
  else
    fail "Deployment must run as non-root (set container.securityContext.runAsNonRoot: true or a non-zero runAsUser, or pod-level equivalent)."
  fi
fi

# Validate allowPrivilegeEscalation=false (container-level preferred)
if [[ "$allowPE_container" == "false" ]] || [[ "$allowPE_pod" == "false" ]]; then
  :
else
  fail "allowPrivilegeEscalation must be set to false (container or pod level)."
fi

# Validate NET_BIND_SERVICE capability present (container-level)
if [[ -z "$caps_add_container" ]] || ! echo "$caps_add_container" | grep -q "NET_BIND_SERVICE"; then
  fail "Container must add capability NET_BIND_SERVICE at securityContext.capabilities.add."
fi

# 2) Ensure rollout succeeded
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 || fail "Deployment '$DEP' did not become Ready."

# 3) Check /net-acm/id.sh exists and works
[[ -f /net-acm/id.sh ]] || fail "/net-acm/id.sh not found. Create a script that prints the pod's UID (e.g., using 'kubectl exec ... id -u')."
[[ -x /net-acm/id.sh ]] || fail "/net-acm/id.sh exists but is not executable (chmod +x /net-acm/id.sh)."

# Execute script and validate it prints a numeric uid (non-root preferred: non-zero)
SCRIPT_OUT="$(/net-acm/id.sh 2>/dev/null | tr -d '\r' | tail -n1)"
[[ -n "$SCRIPT_OUT" ]] || fail "/net-acm/id.sh produced no output."
if ! echo "$SCRIPT_OUT" | grep -Eq '^[0-9]+$'; then
  fail "/net-acm/id.sh should print only the numeric UID (e.g., '1000'). Got: '$SCRIPT_OUT'"
fi

if [[ "$SCRIPT_OUT" == "0" ]]; then
  fail "/net-acm/id.sh indicates UID 0 (root). Workload must run as non-root."
fi

pass "Security settings and UID verification script are correct. (non-root, no-priv-escalation, NET_BIND_SERVICE, /net-acm/id.sh OK)"

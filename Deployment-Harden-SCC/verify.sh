#!/bin/bash
set -euo pipefail

NS="net-acm"
DEP="busybox"
CONTAINER_INDEX=0

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Sanity checks
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get deploy "$DEP" >/dev/null 2>&1 || fail "Deployment '$DEP' not found in '$NS'."

# Need jq to parse
jq -e . >/dev/null 2>&1 || fail "jq not available on the runner."

JSON=$(kubectl -n "$NS" get deploy "$DEP" -o json)

# Pull container-level securityContext (prefer container, allow pod-level fallback)
runAsNonRoot_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.runAsNonRoot // empty")
runAsUser_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.runAsUser // empty")
allowPE_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.allowPrivilegeEscalation // empty")
caps_add_container=$(echo "$JSON" | jq -r ".spec.template.spec.containers[$CONTAINER_INDEX].securityContext.capabilities.add // empty")

runAsNonRoot_pod=$(echo "$JSON" | jq -r ".spec.template.spec.securityContext.runAsNonRoot // empty")
allowPE_pod=$(echo "$JSON" | jq -r ".spec.template.spec.securityContext.allowPrivilegeEscalation // empty")

# 1) Runs as non-root (container-level OR pod-level OR explicit non-zero runAsUser)
if [[ "$runAsNonRoot_container" == "true" || "$runAsNonRoot_pod" == "true" ]]; then
  :
elif [[ -n "$runAsUser_container" && "$runAsUser_container" != "0" ]]; then
  :
else
  fail "Set non-root: container.securityContext.runAsNonRoot: true (or non-zero runAsUser), or pod-level equivalent."
fi

# 2) allowPrivilegeEscalation: false (container- or pod-level)
if [[ "$allowPE_container" == "false" || "$allowPE_pod" == "false" ]]; then
  :
else
  fail "Set allowPrivilegeEscalation: false (container or pod level)."
fi

# 3) NET_BIND_SERVICE capability added (container-level)
if [[ -z "$caps_add_container" ]] || ! echo "$caps_add_container" | grep -q "NET_BIND_SERVICE"; then
  fail "Add capability NET_BIND_SERVICE under container.securityContext.capabilities.add."
fi

# Ensure rollout success
kubectl -n "$NS" rollout status deploy/"$DEP" --timeout=120s >/dev/null 2>&1 || fail "Deployment did not become Ready."

pass "Deployment hardened: non-root, no-priv-escalation, NET_BIND_SERVICE present."

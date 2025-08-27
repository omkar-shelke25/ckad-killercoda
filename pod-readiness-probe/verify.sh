#!/bin/bash
set -euo pipefail

NS="default"
POD="pod6"
IMG="busybox:1.31.0"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

# jq requirement
command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# 1) Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."

# 2) Image check
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Container image must be '$IMG' (found '$PIMG')."

# Fetch full JSON once
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)

# 3) Command intent check (accepts any YAML style)
CMD=$(echo "$JSON" | jq -r '.spec.containers[0].command | join(" ")')
# If command might be under args instead, you could extend checks, but this task uses 'command'
[[ -n "$CMD" ]] || fail "Container 'command' not set."
echo "$CMD" | grep -q "/bin/sh" || fail "Command must include '/bin/sh'."
echo "$CMD" | grep -q "touch /tmp/ready" || fail "Command must include 'touch /tmp/ready'."
echo "$CMD" | grep -q "sleep 1d" || fail "Command must include 'sleep 1d'."

# 4) ReadinessProbe presence & intent
HAS_RP=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe // empty')
[[ -n "$HAS_RP" ]] || fail "readinessProbe is missing."

RP_TYPE=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe | keys[]' | tr '\n' ' ')
echo "$RP_TYPE" | grep -q "exec" || fail "readinessProbe must be of type 'exec'."

RP_CMD=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.exec.command | join(" ")')
[[ -n "$RP_CMD" ]] || fail "readinessProbe.exec.command not set."
echo "$RP_CMD" | grep -q "/bin/sh" || fail "readinessProbe command must include '/bin/sh'."
echo "$RP_CMD" | grep -q "cat /tmp/ready" || fail "readinessProbe must include 'cat /tmp/ready'."

# 5) Timings
RP_INIT=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.initialDelaySeconds // empty')
RP_PER=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.periodSeconds // empty')
[[ "$RP_INIT" == "5" ]] || fail "readinessProbe.initialDelaySeconds must be 5 (found: ${RP_INIT:-<none>})."
[[ "$RP_PER" == "10" ]] || fail "readinessProbe.periodSeconds must be 10 (found: ${RP_PER:-<none>})."

# 6) Pod becomes Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=90s >/dev/null 2>&1 \
  || fail "Pod '$POD' did not become Ready."

pass "Verification successful! Pod '$POD' meets all requirements."

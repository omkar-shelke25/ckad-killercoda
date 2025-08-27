#!/bin/bash
set -euo pipefail

NS="default"
POD="pod6"
IMG="busybox:1.31.0"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq not found. Please install jq."

# Pod exists
kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1 || fail "Pod '$POD' not found in namespace '$NS'."

# Image
PIMG=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}')
[[ "$PIMG" == "$IMG" ]] || fail "Container image must be '$IMG' (found '$PIMG')."

# Command
JSON=$(kubectl -n "$NS" get pod "$POD" -o json)
CMD=$(echo "$JSON" | jq -r '.spec.containers[0].command | @sh' | tr -d "'")
[[ "$CMD" == '[/bin/sh -c touch /tmp/ready && sleep 1d]' ]] || fail "Command must be '/bin/sh -c touch /tmp/ready && sleep 1d' (found: $CMD)."

# Readiness probe exec, initialDelay=5, period=10, command cat /tmp/ready
RP_CMD=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.exec.command | @sh' | tr -d "'")
RP_INIT=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.initialDelaySeconds // empty')
RP_PER=$(echo "$JSON" | jq -r '.spec.containers[0].readinessProbe.periodSeconds // empty')

[[ "$RP_CMD" == '[/bin/sh -c cat /tmp/ready]' ]] || fail "readinessProbe must run 'cat /tmp/ready' (found: $RP_CMD)."
[[ "$RP_INIT" == "5" ]] || fail "readinessProbe.initialDelaySeconds must be 5 (found: $RP_INIT)."
[[ "$RP_PER" == "10" ]] || fail "readinessProbe.periodSeconds must be 10 (found: $RP_PER)."

# Pod Ready
kubectl -n "$NS" wait --for=condition=Ready "pod/$POD" --timeout=90s >/dev/null 2>&1 || \
  fail "Pod '$POD' did not become Ready."

pass "Verification successful! Pod '$POD' satisfies all requirements."

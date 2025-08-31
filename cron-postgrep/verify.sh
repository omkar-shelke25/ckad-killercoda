#!/bin/bash
set -euo pipefail

NS="production"
CJ="database-backup"

pass(){ echo "✅ $1"; exit 0; }
fail(){ echo "❌ $1"; exit 1; }

# Check namespace
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# CronJob exists
kubectl -n "$NS" get cronjob "$CJ" >/dev/null 2>&1 || fail "CronJob '$CJ' not found in $NS."

# Schedule check
SCHED="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.schedule}')"
[[ "$SCHED" == "0 3 * * *" ]] || fail "CronJob schedule must be '0 3 * * *' (found: $SCHED)."

# Image check
IMG="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}')"
[[ "$IMG" == "postgres:13-alpine" ]] || fail "Image must be postgres:13-alpine (found: $IMG)."

# Command check
CMD="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].command}')"
echo "$CMD" | grep -q "Starting DB backup" || fail "Command must simulate DB backup (echo 'Starting DB backup...')."

# ConcurrencyPolicy check
CONC="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.concurrencyPolicy}')"
[[ "$CONC" == "Forbid" ]] || fail "concurrencyPolicy must be Forbid."

# Deadline check
DEADLINE="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.startingDeadlineSeconds}')"
[[ "$DEADLINE" == "120" ]] || fail "startingDeadlineSeconds must be 120."

# RestartPolicy check
RESTART="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}')"
[[ "$RESTART" == "Never" ]] || fail "restartPolicy must be Never."

# History limits check
SUCC="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.successfulJobsHistoryLimit}')"
FAILHIST="$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.failedJobsHistoryLimit}')"
[[ "$SUCC" == "3" ]] || fail "successfulJobsHistoryLimit must be 3."
[[ "$FAILHIST" == "1" ]] || fail "failedJobsHistoryLimit must be 1."

pass "CronJob '$CJ' in '$NS' is configured correctly."

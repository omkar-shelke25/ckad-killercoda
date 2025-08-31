#!/bin/bash
set -euo pipefail

NS="payment"
CJ="db-backup"
JOB="manual-db-backup"

pass(){ echo "✅ $1"; exit 0; }
fail(){ echo "❌ $1"; exit 1; }

# 1. Namespace check
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."

# 2. CronJob existence
kubectl -n "$NS" get cronjob "$CJ" >/dev/null 2>&1 || fail "CronJob '$CJ' not found in $NS."

# 3. CronJob spec checks
SCHED=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.schedule}')
[[ "$SCHED" == "*/10 * * * *" ]] || fail "Schedule must be '*/10 * * * *' (found: $SCHED)."

IMG=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}')
[[ "$IMG" == "busybox" ]] || fail "Image must be busybox (found: $IMG)."

CMD=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].command}')
echo "$CMD" | grep -q "Starting backup" || fail "Command must print 'Starting backup'."

RESTART=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}')
[[ "$RESTART" == "OnFailure" ]] || fail "restartPolicy must be OnFailure."

SUCC=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.successfulJobsHistoryLimit}')
FAILHIST=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.failedJobsHistoryLimit}')
[[ "$SUCC" == "3" ]] || fail "successfulJobsHistoryLimit must be 3."
[[ "$FAILHIST" == "1" ]] || fail "failedJobsHistoryLimit must be 1."

DL=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.startingDeadlineSeconds}')
[[ "$DL" == "100" ]] || fail "startingDeadlineSeconds must be 100 (found: $DL)."

# 4. Manual Job existence
kubectl -n "$NS" get job "$JOB" >/dev/null 2>&1 || fail "Manual Job '$JOB' not found in $NS."

pass "CronJob '$CJ' and manual Job '$JOB' in namespace '$NS' are correctly configured."

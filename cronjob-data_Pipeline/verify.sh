#!/bin/bash
set -euo pipefail

NS="batch"
CJ="data-pipeline"

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

# Namespace & CronJob exist
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
kubectl -n "$NS" get cronjob "$CJ" >/dev/null 2>&1 || fail "CronJob '$CJ' not found in '$NS'."

# 1) CronJob Spec checks
SCHED=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.schedule}')
[[ "$SCHED" == "*/10 * * * *" ]] || fail "Schedule must be '*/10 * * * *' (found: $SCHED)."

CONC=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.concurrencyPolicy}')
[[ "$CONC" == "Forbid" ]] || fail "concurrencyPolicy must be Forbid."

SUCC=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.successfulJobsHistoryLimit}')
[[ "$SUCC" == "2" ]] || fail "successfulJobsHistoryLimit must be 2 (found: $SUCC)."

FAILHIST=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.failedJobsHistoryLimit}')
[[ "$FAILHIST" == "1" ]] || fail "failedJobsHistoryLimit must be 1 (found: $FAILHIST)."

# 2) Job template checks (completions/parallelism/retries/ttl/activeDeadline)
BACKOFF=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.backoffLimit}')
[[ "$BACKOFF" == "3" ]] || fail "backoffLimit must be 3 (found: $BACKOFF)."

COMPLETIONS=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.completions}')
[[ "$COMPLETIONS" == "2" ]] || fail "completions must be 2 (found: $COMPLETIONS)."

PARALLELISM=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.parallelism}')
[[ "$PARALLELISM" == "1" ]] || fail "parallelism must be 1 (found: $PARALLELISM)."

TTL=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.ttlSecondsAfterFinished}')
[[ "$TTL" == "90" ]] || fail "ttlSecondsAfterFinished must be 90 (found: $TTL)."

ADL=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.activeDeadlineSeconds}')
[[ "$ADL" == "50" ]] || fail "activeDeadlineSeconds must be 50 (found: $ADL)."

# 3) Pod template checks
IMG=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}')
[[ "$IMG" == "busybox" ]] || fail "Container image must be 'busybox' (found: $IMG)."

CMD=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].command}')
echo "$CMD" | grep -q "Running Data Job" || fail "Command must echo 'Running Data Job'."

RESTART=$(kubectl -n "$NS" get cj "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}')
[[ "$RESTART" == "Never" ]] || fail "Pod restartPolicy must be 'Never' (found: $RESTART)."

pass "CronJob '$CJ' in namespace '$NS' satisfies all real-life requirements."

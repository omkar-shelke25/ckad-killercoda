#!/bin/bash
set -euo pipefail

NS="batch"
NAME="task-cron"

pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; exit 1; }

# 1) Namespace exists
kubectl get ns "${NS}" >/dev/null 2>&1 || fail "Namespace '${NS}' not found."

# 2) CronJob exists
kubectl get cronjob "${NAME}" -n "${NS}" >/dev/null 2>&1 || fail "CronJob '${NAME}' not found in namespace '${NS}'."

# Helper function for jsonpath
jp() {
  kubectl get cronjob "${NAME}" -n "${NS}" -o jsonpath="$1" 2>/dev/null
}

# 3) Schedule check
SCHEDULE="$(jp '{.spec.schedule}')"
[ "${SCHEDULE}" = "*/5 * * * *" ] || fail "Schedule is '${SCHEDULE}', expected '*/5 * * * *'."
pass "Schedule set to every 5 minutes."

# 4) Job-level fields
BACKOFF_LIMIT="$(jp '{.spec.jobTemplate.spec.backoffLimit}')"
[ "${BACKOFF_LIMIT}" = "2" ] || fail "backoffLimit is '${BACKOFF_LIMIT}', expected '2'."
pass "backoffLimit=2"

COMPLETIONS="$(jp '{.spec.jobTemplate.spec.completions}')"
[ "${COMPLETIONS}" = "4" ] || fail "completions is '${COMPLETIONS}', expected '4'."
pass "completions=4"

PARALLELISM="$(jp '{.spec.jobTemplate.spec.parallelism}')"
[ "${PARALLELISM}" = "2" ] || fail "parallelism is '${PARALLELISM}', expected '2'."
pass "parallelism=2"

TTL="$(jp '{.spec.jobTemplate.spec.ttlSecondsAfterFinished}')"
[ "${TTL}" = "120" ] || fail "ttlSecondsAfterFinished is '${TTL}', expected '120'."
pass "ttlSecondsAfterFinished=120"

ADS="$(jp '{.spec.jobTemplate.spec.activeDeadlineSeconds}')"
[ "${ADS}" = "40" ] || fail "activeDeadlineSeconds is '${ADS}', expected '40'."
pass "activeDeadlineSeconds=40"

# 5) Pod template fields
RESTART_POLICY="$(jp '{.spec.jobTemplate.spec.template.spec.restartPolicy}')"
[ "${RESTART_POLICY}" = "Never" ] || fail "restartPolicy is '${RESTART_POLICY}', expected 'Never'."
pass "restartPolicy=Never"

IMAGE="$(jp '{.spec.jobTemplate.spec.template.spec.containers[0].image}')"
[ "${IMAGE}" = "busybox" ] || fail "container image is '${IMAGE}', expected 'busybox'."
pass "container image=busybox"

# 6) Command check
CMD="$(kubectl get cronjob "${NAME}" -n "${NS}" \
  -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].command[*]}')"

CMD="$(echo "${CMD}" | tr -s ' ')"

echo "${CMD}" | grep -qi "echo Processing" \
  || fail "command must include: echo Processing"

echo "${CMD}" | grep -qi "sleep 30" \
  || fail "command must include: sleep 30"

pass "command includes 'echo Processing' and 'sleep 30'."

echo "✅ Verification successful! CronJob '${NAME}' in namespace '${NS}' is correctly configured."

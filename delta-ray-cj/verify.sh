#!/usr/bin/env bash
set -euo pipefail

#=== Config ==============================================================
NS="delta"
CRONJOB_NAME="delta-ray"
JOB_NAME="manual-delta-ray"
EXPECTED_IMAGE="public.ecr.aws/docker/library/busybox:stable"
EXPECTED_SCHEDULE="*/45 * * * *"
EXPECTED_SUCCESS_HISTORY=33
EXPECTED_FAILED_HISTORY=19
EXPECTED_DEADLINE=50
EXPECTED_RESTART_POLICY="Never"

#=== Helpers ============================================================
pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

need(){
  command -v "$1" >/dev/null 2>&1 || fail "Required dependency '$1' not found in PATH"
}

jq_req(){
  local filt="$1"; shift
  jq -e "$filt" "$@" >/dev/null
}

echo "🔍 Verifying Delta-Ray CronJob and Job configuration..."
echo ""

#=== Preflight ==========================================================
need kubectl
need jq

# Check namespace
kubectl get namespace "$NS" >/dev/null 2>&1 || fail "Namespace '$NS' not found."
pass "Namespace '$NS' exists"

#========================
# Part 1: CronJob Verification
#========================
echo ""
echo "Checking CronJob '$CRONJOB_NAME' configuration..."

# 1) CronJob exists
kubectl -n "$NS" get cronjob "$CRONJOB_NAME" >/dev/null 2>&1 || fail "CronJob '$CRONJOB_NAME' not found in namespace '$NS'."
pass "CronJob '$CRONJOB_NAME' exists"

# Get CronJob JSON
CRONJOB_JSON="$(kubectl -n "$NS" get cronjob "$CRONJOB_NAME" -o json)"

# 2) Schedule is correct
ACTUAL_SCHEDULE="$(echo "$CRONJOB_JSON" | jq -r '.spec.schedule')"
[[ "$ACTUAL_SCHEDULE" == "$EXPECTED_SCHEDULE" ]] || fail "CronJob schedule must be '$EXPECTED_SCHEDULE', found '$ACTUAL_SCHEDULE'."
pass "CronJob schedule is correct: '$EXPECTED_SCHEDULE' (every 45 minutes)"

# 3) Successful jobs history limit
ACTUAL_SUCCESS_HISTORY="$(echo "$CRONJOB_JSON" | jq -r '.spec.successfulJobsHistoryLimit // "null"')"
[[ "$ACTUAL_SUCCESS_HISTORY" == "$EXPECTED_SUCCESS_HISTORY" ]] || fail "CronJob successfulJobsHistoryLimit must be $EXPECTED_SUCCESS_HISTORY, found '$ACTUAL_SUCCESS_HISTORY'."
pass "CronJob successfulJobsHistoryLimit is correct: $EXPECTED_SUCCESS_HISTORY"

# 4) Failed jobs history limit
ACTUAL_FAILED_HISTORY="$(echo "$CRONJOB_JSON" | jq -r '.spec.failedJobsHistoryLimit // "null"')"
[[ "$ACTUAL_FAILED_HISTORY" == "$EXPECTED_FAILED_HISTORY" ]] || fail "CronJob failedJobsHistoryLimit must be $EXPECTED_FAILED_HISTORY, found '$ACTUAL_FAILED_HISTORY'."
pass "CronJob failedJobsHistoryLimit is correct: $EXPECTED_FAILED_HISTORY"

# 5) Active deadline seconds
ACTUAL_DEADLINE="$(echo "$CRONJOB_JSON" | jq -r '.spec.jobTemplate.spec.activeDeadlineSeconds // "null"')"
[[ "$ACTUAL_DEADLINE" == "$EXPECTED_DEADLINE" ]] || fail "CronJob activeDeadlineSeconds must be $EXPECTED_DEADLINE, found '$ACTUAL_DEADLINE'."
pass "CronJob activeDeadlineSeconds is correct: $EXPECTED_DEADLINE seconds"

# 6) Restart policy
ACTUAL_RESTART_POLICY="$(echo "$CRONJOB_JSON" | jq -r '.spec.jobTemplate.spec.template.spec.restartPolicy // "null"')"
[[ "$ACTUAL_RESTART_POLICY" == "$EXPECTED_RESTART_POLICY" ]] || fail "CronJob restartPolicy must be '$EXPECTED_RESTART_POLICY', found '$ACTUAL_RESTART_POLICY'."
pass "CronJob restartPolicy is correct: '$EXPECTED_RESTART_POLICY'"

# 7) Image
ACTUAL_IMAGE="$(echo "$CRONJOB_JSON" | jq -r '.spec.jobTemplate.spec.template.spec.containers[0].image // "null"')"
[[ "$ACTUAL_IMAGE" == "$EXPECTED_IMAGE" ]] || fail "CronJob container image must be '$EXPECTED_IMAGE', found '$ACTUAL_IMAGE'."
pass "CronJob container image is correct: '$EXPECTED_IMAGE'"

# 8) Command exists and contains expected strings
COMMAND_JSON="$(echo "$CRONJOB_JSON" | jq -r '.spec.jobTemplate.spec.template.spec.containers[0].command // [] | join(" ")')"
[[ "$COMMAND_JSON" == *"Delta-Ray Diagnostic"* ]] || fail "CronJob command must contain 'Delta-Ray Diagnostic'."
[[ "$COMMAND_JSON" == *"Scanning cosmic field"* ]] || fail "CronJob command must contain 'Scanning cosmic field'."
[[ "$COMMAND_JSON" == *"Telemetry uplink complete"* ]] || fail "CronJob command must contain 'Telemetry uplink complete'."
pass "CronJob command contains expected diagnostic messages"

#========================
# Part 2: Manual Job Verification
#========================
echo ""
echo "Checking manual Job '$JOB_NAME' configuration..."

# 9) Job exists
kubectl -n "$NS" get job "$JOB_NAME" >/dev/null 2>&1 || fail "Job '$JOB_NAME' not found in namespace '$NS'."
pass "Job '$JOB_NAME' exists"

# Get Job JSON
JOB_JSON="$(kubectl -n "$NS" get job "$JOB_NAME" -o json)"

# 10) Active deadline seconds
ACTUAL_JOB_DEADLINE="$(echo "$JOB_JSON" | jq -r '.spec.activeDeadlineSeconds // "null"')"
[[ "$ACTUAL_JOB_DEADLINE" == "$EXPECTED_DEADLINE" ]] || fail "Job activeDeadlineSeconds must be $EXPECTED_DEADLINE, found '$ACTUAL_JOB_DEADLINE'."
pass "Job activeDeadlineSeconds is correct: $EXPECTED_DEADLINE seconds"

# 11) Restart policy
ACTUAL_JOB_RESTART_POLICY="$(echo "$JOB_JSON" | jq -r '.spec.template.spec.restartPolicy // "null"')"
[[ "$ACTUAL_JOB_RESTART_POLICY" == "$EXPECTED_RESTART_POLICY" ]] || fail "Job restartPolicy must be '$EXPECTED_RESTART_POLICY', found '$ACTUAL_JOB_RESTART_POLICY'."
pass "Job restartPolicy is correct: '$EXPECTED_RESTART_POLICY'"

# 12) Image
ACTUAL_JOB_IMAGE="$(echo "$JOB_JSON" | jq -r '.spec.template.spec.containers[0].image // "null"')"
[[ "$ACTUAL_JOB_IMAGE" == "$EXPECTED_IMAGE" ]] || fail "Job container image must be '$EXPECTED_IMAGE', found '$ACTUAL_JOB_IMAGE'."
pass "Job container image is correct: '$EXPECTED_IMAGE'"

# 13) Command exists
JOB_COMMAND_JSON="$(echo "$JOB_JSON" | jq -r '.spec.template.spec.containers[0].command // [] | join(" ")')"
[[ "$JOB_COMMAND_JSON" == *"Delta-Ray Diagnostic"* ]] || fail "Job command must contain 'Delta-Ray Diagnostic'."
pass "Job command contains expected diagnostic messages"

# 14) Job completion status
echo ""
echo "Waiting for Job '$JOB_NAME' to complete (max 60s)..."
if kubectl wait --for=condition=complete job/"$JOB_NAME" -n "$NS" --timeout=60s >/dev/null 2>&1; then
  pass "Job '$JOB_NAME' completed successfully"
  
  # 15) Check job logs for expected output
  echo ""
  echo "Verifying Job output..."
  JOB_LOGS="$(kubectl logs job/"$JOB_NAME" -n "$NS" 2>/dev/null || echo "")"
  
  if [[ -z "$JOB_LOGS" ]]; then
    fail "Could not retrieve logs from Job '$JOB_NAME'."
  fi
  
  [[ "$JOB_LOGS" == *"🛰️ Initiating Delta-Ray Diagnostic"* ]] || fail "Job logs must contain '🛰️ Initiating Delta-Ray Diagnostic'."
  [[ "$JOB_LOGS" == *"🔭 Cycle"* ]] && [[ "$JOB_LOGS" == *"Scanning cosmic field"* ]] || fail "Job logs must contain scanning cycle messages."
  [[ "$JOB_LOGS" == *"💾 Telemetry uplink complete"* ]] && [[ "$JOB_LOGS" == *"Mission success"* ]] || fail "Job logs must contain success message."
  
  pass "Job output contains all expected diagnostic messages"
  
  # Count cycles in output

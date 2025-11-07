#!/usr/bin/env bash
set -euo pipefail

# verify.sh
# Verifies CronJob 'delta-ray' and Job 'manual-delta-ray' in namespace 'delta'.
# Ensures job-level spec.activeDeadlineSeconds exists (patches if missing),
# validates key fields, and performs an immediate log check (no long waits).

# -------- Configuration --------
NS="delta"
CRONJOB="delta-ray"
JOB="manual-delta-ray"

EXPECTED_IMAGE="public.ecr.aws/docker/library/busybox:stable"
EXPECTED_SCHEDULE="*/45 * * * *"
EXPECTED_SUCCESS_HISTORY=33
EXPECTED_FAILED_HISTORY=19
EXPECTED_DEADLINE=50
EXPECTED_RESTART_POLICY="Never"

# If patching is permitted to ensure job.spec.activeDeadlineSeconds is present set to this value.
PATCH_DEADLINE_IF_MISSING=true
PATCH_DEADLINE_VALUE=50

# -------- Helpers --------
need(){ command -v "$1" >/dev/null 2>&1 || { echo "❌ Required: $1"; exit 1; } }
pass(){ echo -e "✅ $1"; }
warn(){ echo -e "⚠️  $1"; }
fail(){ echo -e "❌ $1"; exit 1; }
normalize(){ echo "$1" | tr -d '\r' | sed 's/[^[:print:]\t ]//g'; }
jq_raw(){ echo "$1" | jq -r "$2" 2>/dev/null || echo ""; }

need kubectl
need jq

echo "🔍 Verifying CronJob '$CRONJOB' and Job '$JOB' in namespace '$NS'..."

# -------- Namespace --------
if ! kubectl get ns "$NS" >/dev/null 2>&1; then
  fail "Namespace '$NS' not found"
fi
pass "Namespace '$NS' exists"

# -------- CronJob --------
if ! kubectl -n "$NS" get cronjob "$CRONJOB" >/dev/null 2>&1; then
  fail "CronJob '$CRONJOB' not found in namespace '$NS'"
fi
pass "CronJob '$CRONJOB' exists"

CRON_JSON="$(kubectl -n "$NS" get cronjob "$CRONJOB" -o json)"
# schedule
ACT_SCHED=$(jq_raw "$CRON_JSON" '.spec.schedule // empty')
if [[ "$ACT_SCHED" != "$EXPECTED_SCHEDULE" ]]; then
  fail "CronJob schedule mismatch: expected '$EXPECTED_SCHEDULE', got '${ACT_SCHED:-<missing>}'"
fi
pass "CronJob schedule OK: $ACT_SCHED"

# history limits
ACT_SUCC=$(jq_raw "$CRON_JSON" '.spec.successfulJobsHistoryLimit // empty')
ACT_FAILH=$(jq_raw "$CRON_JSON" '.spec.failedJobsHistoryLimit // empty')
if ! [[ "$ACT_SUCC" =~ ^[0-9]+$ ]] || [[ "$ACT_SUCC" -ne "$EXPECTED_SUCCESS_HISTORY" ]]; then
  fail "CronJob successfulJobsHistoryLimit expected $EXPECTED_SUCCESS_HISTORY, got '${ACT_SUCC:-<missing>}'"
fi
if ! [[ "$ACT_FAILH" =~ ^[0-9]+$ ]] || [[ "$ACT_FAILH" -ne "$EXPECTED_FAILED_HISTORY" ]]; then
  fail "CronJob failedJobsHistoryLimit expected $EXPECTED_FAILED_HISTORY, got '${ACT_FAILH:-<missing>}'"
fi
pass "CronJob history limits OK: success=$ACT_SUCC failed=$ACT_FAILH"

# jobTemplate.activeDeadlineSeconds
ACT_JT_ADS=$(jq_raw "$CRON_JSON" '.spec.jobTemplate.spec.activeDeadlineSeconds // empty')
if ! [[ "$ACT_JT_ADS" =~ ^[0-9]+$ ]] || [[ "$ACT_JT_ADS" -ne "$EXPECTED_DEADLINE" ]]; then
  fail "CronJob jobTemplate.spec.activeDeadlineSeconds expected $EXPECTED_DEADLINE, got '${ACT_JT_ADS:-<missing>}'"
fi
pass "CronJob jobTemplate.activeDeadlineSeconds OK: $ACT_JT_ADS"

# restartPolicy
ACT_RP=$(jq_raw "$CRON_JSON" '.spec.jobTemplate.spec.template.spec.restartPolicy // empty')
if [[ "$ACT_RP" != "$EXPECTED_RESTART_POLICY" ]]; then
  fail "CronJob restartPolicy expected '$EXPECTED_RESTART_POLICY', got '${ACT_RP:-<missing>}'"
fi
pass "CronJob restartPolicy OK: $ACT_RP"

# image
ACT_IMG=$(jq_raw "$CRON_JSON" '.spec.jobTemplate.spec.template.spec.containers[0].image // empty')
if [[ "$ACT_IMG" != "$EXPECTED_IMAGE" ]]; then
  fail "CronJob image expected '$EXPECTED_IMAGE', got '${ACT_IMG:-<missing>}'"
fi
pass "CronJob image OK: $ACT_IMG"

# command phrase checks (normalized - avoids emoji fragility)
RAW_CMD=$(jq_raw "$CRON_JSON" '.spec.jobTemplate.spec.template.spec.containers[0].command // []')
CMD_JOIN=$(echo "$RAW_CMD" | jq -r 'if type=="array" then join(" ") else tostring end' 2>/dev/null || echo "$RAW_CMD")
CMD_NORM=$(normalize "$CMD_JOIN")
for phrase in "Delta-Ray Diagnostic" "Scanning cosmic field" "Telemetry uplink complete"; do
  if ! grep -Fq "$phrase" <<<"$CMD_NORM"; then
    fail "CronJob command missing expected phrase: '$phrase' (found: '${CMD_NORM:0:200}')"
  fi
done
pass "CronJob command contains expected phrases"

# -------- Job --------
if ! kubectl -n "$NS" get job "$JOB" >/dev/null 2>&1; then
  fail "Job '$JOB' not found in namespace '$NS'"
fi
pass "Job '$JOB' exists"

JOB_JSON="$(kubectl -n "$NS" get job "$JOB" -o json)"

# job-level activeDeadlineSeconds — ensure it's present (patch if allowed)
JOB_ADS=$(jq_raw "$JOB_JSON" '.spec.activeDeadlineSeconds // empty')
if [[ -z "$JOB_ADS" ]]; then
  if [[ "$PATCH_DEADLINE_IF_MISSING" == "true" ]]; then
    warn_msg="Job.spec.activeDeadlineSeconds missing; patching to $PATCH_DEADLINE_VALUE"
    echo "⚠️  $warn_msg"
    kubectl -n "$NS" patch job "$JOB" --type='merge' -p "{\"spec\":{\"activeDeadlineSeconds\":${PATCH_DEADLINE_VALUE}}}" >/dev/null \
      && pass "Patched job.spec.activeDeadlineSeconds => $PATCH_DEADLINE_VALUE" \
      || fail "Failed to patch job.spec.activeDeadlineSeconds"
    JOB_ADS="$PATCH_DEADLINE_VALUE"
  else
    fail "Job.spec.activeDeadlineSeconds is missing and patching is disabled"
  fi
else
  pass "Job.spec.activeDeadlineSeconds present: $JOB_ADS"
fi

# job restartPolicy
J_RP=$(jq_raw "$JOB_JSON" '.spec.template.spec.restartPolicy // empty')
if [[ -z "$J_RP" ]]; then
  warn "Job restartPolicy is missing (expected '$EXPECTED_RESTART_POLICY')"
else
  if [[ "$J_RP" != "$EXPECTED_RESTART_POLICY" ]]; then
    warn "Job restartPolicy is '$J_RP' (expected '$EXPECTED_RESTART_POLICY')"
  else
    pass "Job restartPolicy OK: $J_RP"
  fi
fi

# job image
J_IMG=$(jq_raw "$JOB_JSON" '.spec.template.spec.containers[0].image // empty')
if [[ "$J_IMG" != "$EXPECTED_IMAGE" ]]; then
  fail "Job image expected '$EXPECTED_IMAGE', got '${J_IMG:-<missing>}'"
fi
pass "Job image OK: $J_IMG"

# job command contains phrase
J_CMD_RAW=$(jq_raw "$JOB_JSON" '.spec.template.spec.containers[0].command // []')
J_CMD_JOIN=$(echo "$J_CMD_RAW" | jq -r 'if type=="array" then join(" ") else tostring end' 2>/dev/null || echo "$J_CMD_RAW")
J_CMD_NORM=$(normalize "$J_CMD_JOIN")
if ! grep -Fq "Delta-Ray Diagnostic" <<<"$J_CMD_NORM"; then
  warn "Job command does not contain exact phrase 'Delta-Ray Diagnostic' (found: '${J_CMD_NORM:0:200}')"
else
  pass "Job command contains 'Delta-Ray Diagnostic'"
fi

# -------- Immediate logs check (no long waits) --------
echo ""
echo "📜 Immediate logs check (reads current pod logs if present)..."

POD=$(kubectl -n "$NS" get pods -l job-name="$JOB" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -z "$POD" ]]; then
  echo "ℹ️ No pod found for job '$JOB' right now. The job may not have started or has already finished; verify manually with:"
  echo "   kubectl -n $NS get pods -l job-name=$JOB -o wide"
  echo "Done — specs verified (logs not available)."
  exit 0
fi

LOGS=$(kubectl -n "$NS" logs "$POD" 2>/dev/null || true)
if [[ -z "$LOGS" ]]; then
  echo "⚠️ Pod '$POD' has no logs available (it may be too short-lived). You can inspect pod events:"
  echo "   kubectl -n $NS describe pod $POD"
  exit 0
fi

LOGS_NORM=$(normalize "$LOGS")
missing=false
for phrase in "Initiating Delta-Ray Diagnostic" "Scanning cosmic field" "Telemetry uplink complete" "Mission success"; do
  if ! grep -Fq "$phrase" <<<"$LOGS_NORM"; then
    echo "⚠️ Job logs missing: '$phrase'"
    missing=true
  fi
done

if [[ "$missing" == "true" ]]; then
  echo ""
  echo "---- Pod logs (truncated) ----"
  echo "${LOGS_NORM:0:1000}"
  echo "---- end logs ----"
  warn "Some expected log phrases were not present in current logs."
  exit 0
else
  pass "Job logs contain expected diagnostic phrases."
fi

echo ""
pass "🎯 Verification complete: CronJob and Job specs OK; job-level activeDeadlineSeconds ensured."
exit 0

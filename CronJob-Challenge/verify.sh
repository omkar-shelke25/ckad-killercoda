#!/bin/bash

# Check if CronJob exists
if ! kubectl get cronjob task-cron -n batch &>/dev/null; then
    echo "❌ CronJob 'task-cron' not found in 'batch' namespace"
    exit 1
fi

# Verify schedule
SCHEDULE=$(kubectl get cronjob task-cron -n batch -o jsonpath='{.spec.schedule}')
if [ "$SCHEDULE" != "*/5 * * * *" ]; then
    echo "❌ Schedule is '$SCHEDULE', expected '*/5 * * * *'"
    exit 1
fi

# Verify completions
COMPLETIONS=$(kubectl get cronjob task-cron -n batch -o jsonpath='{.spec.jobTemplate.spec.completions}')
if [ "$COMPLETIONS" != "4" ]; then
    echo "❌ Completions is '$COMPLETIONS', expected '4'"
    exit 1
fi

# Verify parallelism
PARALLELISM=$(kubectl get cronjob task-cron -n batch -o jsonpath='{.spec.jobTemplate.spec.parallelism}')
if [ "$PARALLELISM" != "2" ]; then
    echo "❌ Parallelism is '$PARALLELISM', expected '2'"
    exit 1
fi

# Verify ttlSecondsAfterFinished
TTL=$(kubectl get cronjob task-cron -n batch -o jsonpath='{.spec.jobTemplate.spec.ttlSecondsAfterFinished}')
if [ "$TTL" != "120" ]; then
    echo "❌ ttlSecondsAfterFinished is '$TTL', expected '120'"
    exit 1
fi

echo "✅ Verification successful! CronJob 'task-cron' is correctly configured."

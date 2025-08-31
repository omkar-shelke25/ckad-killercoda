#!/bin/bash
set -euo pipefail

echo "Preparing environment..."

kubectl get ns production >/dev/null 2>&1 || kubectl create ns production

echo "Namespace 'production' ready for the CronJob task."

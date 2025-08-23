#!/bin/bash
set -euo pipefail

# Prepare lab (idempotent)
kubectl get ns apps >/dev/null 2>&1 || kubectl create namespace apps

echo "Use namespace 'apps'. Provide config strictly as files at /etc/appconfig."

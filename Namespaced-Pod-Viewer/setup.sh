#!/bin/bash
set -euo pipefail

echo "⏳ Initializing scenario..."
kubectl get ns dev-team-1 >/dev/null 2>&1 || kubectl create namespace dev-team-1 >/dev/null
echo "✅ Namespace 'dev-team-1' is ready."
echo "👉 Proceed to create SA, Role, and RoleBinding in 'step1.md'."

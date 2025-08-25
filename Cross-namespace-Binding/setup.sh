#!/bin/bash
set -euo pipefail

echo "Initializing scenario..."
kubectl get ns app-prod >/dev/null 2>&1 || kubectl create namespace app-prod >/dev/null
echo "✅ Namespace 'app-prod' is ready."
echo "👉 Proceed to create SA, Role (pods/log), and RoleBinding as per the task."

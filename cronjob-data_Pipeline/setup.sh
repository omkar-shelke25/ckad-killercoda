#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."
kubectl get ns batch >/dev/null 2>&1 || kubectl create ns batch
echo "✅ Namespace 'batch' is ready."

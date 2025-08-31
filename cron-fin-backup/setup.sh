#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."

# Create payment namespace if not exists
kubectl get ns payment >/dev/null 2>&1 || kubectl create ns payment

echo "✅ Namespace 'payment' is ready."

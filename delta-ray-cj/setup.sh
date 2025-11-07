#!/bin/bash
set -euo pipefail

echo "🛰️ Preparing Delta-Ray lab environment..."

NS="delta"

# Create namespace
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -


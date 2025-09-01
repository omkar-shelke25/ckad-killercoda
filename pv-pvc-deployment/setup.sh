

#!/bin/bash
set -euo pipefail

echo "🚀 Preparing environment..."

# Namespace
kubectl get ns earth >/dev/null 2>&1 || kubectl create ns earth

echo "✅ Namespace 'earth' ready."

#!/bin/bash
set -euo pipefail

NS="pluto"

# Namespace for the challenge
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Host paths for saved artifacts
sudo mkdir -p /opt/course/10
sudo chmod -R 0777 /opt/course/10 || true

echo "✅ Setup complete. Namespace '$NS' ready; artifacts dir /opt/course/10 prepared."

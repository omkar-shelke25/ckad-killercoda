#!/bin/bash
set -euo pipefail

# Create the apps namespace (idempotent)
kubectl get ns apps >/dev/null 2>&1 || kubectl create namespace apps

echo "Setup complete! Use the apps namespace for your resources."

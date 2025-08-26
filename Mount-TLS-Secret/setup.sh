#!/bin/bash
set -euo pipefail

echo "Preparing lab environment..."

NS="security"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"

# Generate a self-signed cert/key if not present, to simulate provided files
if [ ! -f task4.key ] || [ ! -f task4.crt ]; then
  echo "Generating self-signed TLS key/cert (task4.key, task4.crt)..."
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout task4.key -out task4.crt -days 365 \
    -subj "/CN=secure-pod/O=example"
fi

echo "Setup complete! Namespace '$NS' and sample TLS files are ready."

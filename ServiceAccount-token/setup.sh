#!/bin/bash
set -euo pipefail

NS="neptune"
SA="neptune-sa-v2"
SECRET_NAME="neptune-sa-v2-token"
COURSE_DIR="/opt/course/5"

# Create directory for student deliverable
mkdir -p "$COURSE_DIR"
chmod 755 "$COURSE_DIR"

# Create namespace
kubectl create namespace "$NS"

# Create ServiceAccount
kubectl -n "$NS" create serviceaccount "$SA"

# Create a secret with a known token string
TOKEN_STRING="SuperSecretToken123"

kubectl -n "$NS" create secret generic "$SECRET_NAME" \
  --from-literal=token="$TOKEN_STRING"

# Annotate secret so it looks like SA-related
kubectl -n "$NS" annotate secret "$SECRET_NAME" \
  kubernetes.io/service-account.name="$SA"

echo "✅ Setup complete. Secret with encoded token has been created."

#!/bin/bash
set -euo pipefail

COURSE_DIR="/opt/course/21"
WORKDIR="$COURSE_DIR/workdir"
DOCKER_DIR="$COURSE_DIR/docker"
OCI_DIR="$COURSE_DIR/oci"

mkdir -p "$WORKDIR" "$DOCKER_DIR" "$OCI_DIR"

# Sample production-style Dockerfile
cat > "$WORKDIR/Dockerfile" <<'EOF'
FROM alpine:3.18
LABEL maintainer="team@retail-co.example"
RUN apk add --no-cache curl
COPY greeting.txt /greeting.txt
CMD ["sh", "-c", "echo '🚀 RetailCo Analytics API v1.0' && cat /greeting.txt && sleep 3600"]
EOF

cat > "$WORKDIR/greeting.txt" <<'EOF'
This container simulates the RetailCo Analytics API service.
EOF

cd "$WORKDIR"

# Install buildx
export DOCKER_BUILDKIT=1
mkdir -p ~/.docker/cli-plugins/
curl -sSL https://github.com/docker/buildx/releases/download/v0.16.2/buildx-v0.16.2.linux-amd64 \
  -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

echo "🔧 Installed docker-buildx plugin:"
docker buildx version || true

# Create builder
docker buildx create --use --name kc-builder || true
docker buildx inspect kc-builder --bootstrap || true

sleep 3


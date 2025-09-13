#!/bin/bash
set -euo pipefail

echo "🚀 Setting up Docker environment..."

# Setup directories
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



# Enable Docker BuildKit
export DOCKER_BUILDKIT=1

echo "🔧 Installing Docker Buildx..."

# Create plugin directory
mkdir -p ~/.docker/cli-plugins/

# Download buildx with better error handling
if curl -sSL --connect-timeout 30 --max-time 120 --retry 3 --retry-delay 5 \
   "https://github.com/docker/buildx/releases/download/v0.16.2/buildx-v0.16.2.linux-amd64" \
   -o ~/.docker/cli-plugins/docker-buildx; then
    
    chmod +x ~/.docker/cli-plugins/docker-buildx
    echo "✅ Docker buildx downloaded successfully"
else
    echo "❌ Failed to download buildx, trying alternative method..."
    
    # Fallback: try different version or package manager
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq >/dev/null 2>&1 || true
        apt-get install -y docker-buildx-plugin >/dev/null 2>&1 || true
    fi
fi

# Verify installation
if docker buildx version >/dev/null 2>&1; then
    echo "✅ Docker buildx installed successfully:"
    docker buildx version
    
    # Create and setup builder
    docker buildx create --use --name kc-builder --driver docker-container || {
        echo "⚠️ Failed to create custom builder, using default"
    }
    
    # Bootstrap builder
    docker buildx inspect --bootstrap >/dev/null 2>&1 || {
        echo "⚠️ Builder bootstrap failed, but buildx should still work"
    }
    
    echo "🏗️ Available builders:"
    docker buildx ls
else
    echo "❌ Docker buildx installation failed"
    exit 1
fi

echo "✅ Environment setup complete"
echo "📁 Working directory: $WORKDIR"
echo "🐳 Docker BuildKit enabled: $DOCKER_BUILDKIT"

sleep 3

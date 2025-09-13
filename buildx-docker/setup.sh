#!/bin/bash
set -euo pipefail

echo "🚀 Setting up Docker environment (without buildx dependency)..."

COURSE_DIR="/opt/course/21"
WORKDIR="$COURSE_DIR/workdir"
DOCKER_DIR="$COURSE_DIR/docker"
OCI_DIR="$COURSE_DIR/oci"

# Create directories
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

# Enable Docker BuildKit (works with regular docker build too)
export DOCKER_BUILDKIT=1

echo "🔧 Checking Docker availability..."

# Verify Docker is working
if ! docker --version >/dev/null 2>&1; then
    echo "❌ Docker is not available"
    exit 1
fi

echo "✅ Docker is available: $(docker --version)"

# Check if buildx is available (but don't fail if it's not)
if docker buildx version >/dev/null 2>&1; then
    echo "✅ Docker buildx is available: $(docker buildx version)"
    
    # Try to create builder (optional)
    docker buildx create --use --name kc-builder --driver docker-container 2>/dev/null || {
        echo "⚠️  Using default builder"
        docker buildx use default || true
    }
    
    echo "🏗️  Available builders:"
    docker buildx ls 2>/dev/null || echo "Could not list builders"
else
    echo "⚠️  Docker buildx not available, will use regular docker build"
    echo "📝 Note: Multi-platform builds and advanced buildx features won't be available"
fi

# Test basic build functionality
echo "🧪 Testing Docker build functionality..."
if docker build --help >/dev/null 2>&1; then
    echo "✅ Docker build is functional"
else
    echo "❌ Docker build is not working"
    exit 1
fi

# Create a simple test script that works with or without buildx
cat > "$WORKDIR/build.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

echo "🏗️  Building container image..."

# Check if buildx is available
if docker buildx version >/dev/null 2>&1; then
    echo "📦 Using docker buildx for build"
    docker buildx build -t retail-analytics:v1.0 .
else
    echo "📦 Using regular docker build"
    docker build -t retail-analytics:v1.0 .
fi

echo "✅ Build completed"
docker images | grep retail-analytics || echo "⚠️  Image not found in docker images"
EOF

chmod +x "$WORKDIR/build.sh"

echo "✅ Environment setup complete"
echo "📁 Working directory: $WORKDIR"
echo "🐳 Docker BuildKit enabled: $DOCKER_BUILDKIT"
echo "🔨 Build script created: $WORKDIR/build.sh"
echo ""
echo "💡 To build the image, run: cd $WORKDIR && ./build.sh"

sleep 1

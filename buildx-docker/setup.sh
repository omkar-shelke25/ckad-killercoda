#!/bin/bash
set -euo pipefail

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

echo "✅ Docker Buildx setup complete"

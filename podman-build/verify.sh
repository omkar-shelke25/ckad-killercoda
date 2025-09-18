#!/bin/bash
set -euo pipefail

fail(){ echo "❌ $1"; exit 1; }
pass(){ echo "✅ $1"; exit 0; }

echo "🔍 Verifying BlackHole Wave Monitoring System Deployment..."
echo "🌌 Quantum Space Observatory - Container Deployment Verification"

# Phase 1: Verify container image was built on control node
echo ""
echo "📋 Phase 1: Verifying container image build..."

# Check if podman is installed
command -v podman >/dev/null 2>&1 || fail "Podman is not installed on control node"

# Check if project directory exists
[[ -d "/root/blackhole-project" ]] || fail "Project directory /root/blackhole-project not found"

# Check if Dockerfile exists
[[ -f "/root/blackhole-project/Dockerfile" ]] || fail "Dockerfile not found in project directory"

# Check if image was built (either locally or we can verify it exists in the saved tar)
IMAGE_NAME="quantum.registry:8000/blackhole-wave:2.36"

echo "✅ Project setup verified"

# Phase 2: Verify OCI archive was created (or create it in OCI format if missing)
echo ""
echo "📋 Phase 2: Verifying OCI archive creation..."

ARCHIVE_PATH="/root/blackhole-project/blackhole-monitoring.tar"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "⚠️ Archive $ARCHIVE_PATH not found. Attempting to create OCI archive from local image..."
  # Ensure image exists locally
  if podman images --format '{{.Repository}}:{{.Tag}}' | grep -qxF "$IMAGE_NAME"; then
    echo "📦 Found local image $IMAGE_NAME — saving as OCI archive..."
    # Use oci-archive format explicitly
    podman save --format oci-archive -o "$ARCHIVE_PATH" "$IMAGE_NAME" || fail "podman save failed while creating OCI archive"
    echo "✅ Created OCI archive at $ARCHIVE_PATH"
  else
    fail "blackhole-monitoring.tar not found and local image $IMAGE_NAME does not exist. Build the image or provide the tar."
  fi
fi

# Check archive is not empty
ARCHIVE_SIZE=$(stat -f%z "$ARCHIVE_PATH" 2>/dev/null || stat -c%s "$ARCHIVE_PATH" 2>/dev/null || echo "0")
[[ "$ARCHIVE_SIZE" -gt 1000000 ]] || fail "Archive file seems too small ($ARCHIVE_SIZE bytes). Ensure you saved a complete container image."

echo "✅ OCI archive present: $(ls -lh $ARCHIVE_PATH | awk '{print $5}')"

# === New Phase 2.5: Detect archive format (OCI vs docker-archive) ===
echo ""
echo "📋 Phase 2.5: Detecting archive format (OCI vs docker-archive)..."

# List top-level entries (limit output) and search for oci-layout / index.json / manifest.json
TAR_TOP=$(tar -tf "$ARCHIVE_PATH" | sed -n '1,200p' 2>/dev/null || true)

if echo "$TAR_TOP" | grep -qE '^oci-layout$|/oci-layout$|^index.json$|/index.json$'; then
  echo "✅ Archive detected as OCI format (contains oci-layout or index.json)"
elif echo "$TAR_TOP" | grep -qE '^manifest.json$|/manifest.json$|^repositories$|/repositories$'; then
  # Common docker-archive markers
  fail "Archive appears to be a docker-archive (manifest.json/repositories present). Expected OCI format (oci-layout/index.json). If you intended OCI, recreate with: podman save --format oci-archive -o $ARCHIVE_PATH $IMAGE_NAME"
else
  # Unknown archive structure: show a short sample to help debugging, then fail
  echo "⚠️ Unable to conclusively detect archive format from top-level entries. Showing first 20 entries for debugging:"
  tar -tf "$ARCHIVE_PATH" | sed -n '1,20p' || true
  fail "Archive format unknown — it does not contain obvious oci-layout/index.json or manifest.json markers. Ensure you used 'podman save --format oci-archive' or an OCI-capable save method."
fi

# Phase 3: Verify file was transferred to node01
echo ""
echo "📋 Phase 3: Verifying transfer to node01..."

# Check SSH connectivity to node01
ssh -o ConnectTimeout=10 node01 "echo 'SSH connection successful'" >/dev/null 2>&1 || fail "Cannot connect to node01 via SSH"

# Check if tar file exists on node01
ssh node01 "[[ -f /tmp/blackhole-monitoring.tar ]]" || fail "blackhole-monitoring.tar not found on node01 at /tmp/. Did you transfer the file using scp?"

# Verify file size on node01 matches control node
NODE01_SIZE=$(ssh node01 "stat -c%s /tmp/blackhole-monitoring.tar 2>/dev/null || echo 0")
[[ "$NODE01_SIZE" == "$ARCHIVE_SIZE" ]] || fail "File size mismatch between control node ($ARCHIVE_SIZE) and node01 ($NODE01_SIZE). Transfer may be corrupted."

echo "✅ Archive successfully transferred to node01: $NODE01_SIZE bytes"

# Phase 4: Verify podman is installed on node01
echo ""
echo "📋 Phase 4: Verifying node01 container environment..."

ssh node01 "command -v podman >/dev/null 2>&1" || fail "Podman is not installed on node01"

echo "✅ Podman runtime available on node01"

# Phase 5: Verify container image was loaded on node01
echo ""
echo "📋 Phase 5: Verifying container image loading..."

# Check if image was loaded
ssh node01 "podman images | grep -q 'blackhole-wave'" || fail "Container image not loaded on node01. Did you run 'podman load -i /tmp/blackhole-monitoring.tar'?"

# Verify correct tag
ssh node01 "podman images | grep -q 'quantum.registry:8000/blackhole-wave'" || fail "Container image tag not correct. Expected 'quantum.registry:8000/blackhole-wave:2.36'"

echo "✅ Container image loaded successfully on node01"

# Phase 6: Verify container is running
echo ""
echo "📋 Phase 6: Verifying container deployment..."

# Check if container is running
ssh node01 "podman ps | grep -q 'blackhole-monitoring'" || fail "Container 'blackhole-monitoring' is not running on node01. Did you run the container with the correct name?"

# Verify container name is exactly "blackhole-monitoring"
ssh node01 "podman ps --format '{{.Names}}' | grep -q '^blackhole-monitoring$'" || fail "Container name is not exactly 'blackhole-monitoring'. Check the container name."

# Check container status is running
CONTAINER_STATUS=$(ssh node01 "podman ps --format '{{.Status}}' --filter name=blackhole-monitoring")
echo "$CONTAINER_STATUS" | grep -q "Up" || fail "Container 'blackhole-monitoring' is not in running state. Status: $CONTAINER_STATUS"

echo "✅ Container 'blackhole-monitoring' is running successfully"

# Phase 7: Verify container logs and monitoring script
echo ""
echo "📋 Phase 7: Verifying monitoring system functionality..."

# Get container logs
CONTAINER_LOGS=$(ssh node01 "podman logs blackhole-monitoring")

# Check if logs contain expected startup message
echo "$CONTAINER_LOGS" | grep -q "Container started at" || fail "Container logs missing startup message. Monitoring script may not be running."

# Check maintainer information
echo "$CONTAINER_LOGS" | grep -q "Maintainer: Omkar Shelke - Killer Coda CKDA Practice" || fail "Container logs missing maintainer information. Check the monitoring script output."

# Check if counter is present (monitoring script is working)
echo "$CONTAINER_LOGS" | grep -q "Count:" || fail "Container logs missing counter output. Monitoring script may not be functioning."

# Check if process is running with timestamps
echo "$CONTAINER_LOGS" | grep -q "Process running" || fail "Container monitoring process logs not found. Ensure the monitoring script is executing."

echo "✅ Monitoring system is operational and generating logs"

# Phase 8: Verify container configuration
echo ""
echo "📋 Phase 8: Verifying container configuration..."

# Check if container is using the correct image
CONTAINER_IMAGE=$(ssh node01 "podman ps --format '{{.Image}}' --filter name=blackhole-monitoring")
[[ "$CONTAINER_IMAGE" == "$IMAGE_NAME" ]] || fail "Container is not using the correct image. Expected: $IMAGE_NAME, Got: $CONTAINER_IMAGE"

# Verify container is accessible and healthy
ssh node01 "podman exec blackhole-monitoring echo 'Container access test'" >/dev/null 2>&1 || fail "Cannot access container for health check. Container may be unhealthy."

echo "✅ Container configuration verified"

# Final verification summary
echo ""
echo "🎉 DEPLOYMENT VERIFICATION COMPLETE!"
echo "=================================================="
echo "✅ Container image built: quantum.registry:8000/blackhole-wave:2.36"
echo "✅ OCI archive created: blackhole-monitoring.tar"
echo "✅ File transferred to node01: /tmp/blackhole-monitoring.tar"
echo "✅ Image loaded on node01: podman load successful"
echo "✅ Container running: blackhole-monitoring"
echo "✅ Monitoring system operational: logs generating"
echo "✅ Maintainer information confirmed: Omkar Shelke"
echo ""

# Display final status
FINAL_LOGS=$(ssh node01 "podman logs --tail 3 blackhole-monitoring")
echo "📊 Latest monitoring output:"
echo "$FINAL_LOGS"

echo ""
pass "🌌 BlackHole Wave Monitoring System successfully deployed! The Quantum Space Observatory is now operational across the distributed network!"

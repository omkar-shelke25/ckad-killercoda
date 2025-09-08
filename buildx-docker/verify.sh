#!/bin/bash
set -euo pipefail

COURSE_DIR="/opt/course/21"
DOCKER_TAR="$COURSE_DIR/docker/myapp-docker.tar"
OCI_TAR="$COURSE_DIR/oci/myapp-oci.tar"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

[ -f "$DOCKER_TAR" ] || fail "Docker archive missing"
[ -s "$DOCKER_TAR" ] || fail "Docker archive empty"
tar -tf "$DOCKER_TAR" | grep -q manifest.json || fail "Docker archive missing manifest.json"
pass "Docker archive valid"

if docker load -i "$DOCKER_TAR" >/dev/null 2>&1; then
  docker image inspect retailco/analytics-api:v1 >/dev/null 2>&1 && pass "Image retailco/analytics-api:v1 loaded"
fi

[ -f "$OCI_TAR" ] || fail "OCI archive missing"
[ -s "$OCI_TAR" ] || fail "OCI archive empty"
tar -tf "$OCI_TAR" | grep -q oci-layout || fail "OCI archive missing oci-layout"
pass "OCI archive valid"

#!/bin/bash

OCI_FILE="/root/flask-web-oci.tar"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "Checking requirements..."
echo ""

# Check if image exists (with or without localhost/ prefix)
if podman images --format "{{.Repository}}:{{.Tag}}" | grep -qE "^(localhost/)?flask-web:1\.0$"; then
    pass "Image 'flask-web:1.0' is built"
else
    fail "Image 'flask-web:1.0' not found. Run: cd /root/ckad && podman build -t flask-web:1.0 ."
fi

# Check if OCI archive file exists
if [ -f "$OCI_FILE" ]; then
    pass "OCI archive file exists at /root/flask-web-oci.tar"
else
    fail "OCI archive not found. Run: podman save --format oci-archive -o /root/flask-web-oci.tar flask-web:1.0"
fi

# Check if it's valid OCI format
if tar -tf "$OCI_FILE" | grep -q "oci-layout"; then
    pass "File is in valid OCI format"
else
    fail "File is not in OCI format. Use: podman save --format oci-archive"
fi

echo ""
echo "✅ All checks passed!"
echo "🎯 Image built and saved in OCI format successfully!"

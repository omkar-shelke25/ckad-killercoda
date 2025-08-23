#!/bin/bash
set -euo pipefail

# Prepare path for the command script required by the task
sudo mkdir -p /opt/course/2
sudo chmod -R 0777 /opt/course/2 || true

echo "✅ Environment ready. Create the Pod and the status script as instructed."

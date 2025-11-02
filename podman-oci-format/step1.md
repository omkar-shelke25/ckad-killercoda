# 🐳 CKAD: Build Flask Image and Save in OCI Format with Podman

A simple Python Flask web application needs to be containerized using Podman and saved in OCI format for offline distribution.

## 📋 Task Requirements

In the **`/root/ckad`** directory, you will find all necessary files:
- **`app.py`** - Flask application that responds with `Welcome to CKAD!` on port `8080`
- **`requirements.txt`** - Python dependencies
- **`Containerfile`** - Container definition (Podman's equivalent of Dockerfile)

Your tasks:
1. Build a container image named `flask-web:1.0` using **Podman**
2. Save the image in **OCI format** as `/root/flask-web-oci.tar`

> **Important**: Use Podman commands (not Docker). Do NOT push the image to any registry. The OCI archive file must exist at `/root/flask-web-oci.tar` at the end of the task.

---

## 💡 Complete Solution

<details>
<summary>🔧 Click to view step-by-step solution</summary>

```bash
# Navigate to the working directory
cd /root/ckad

# Verify files exist
ls -la

# Build the container image using Podman
# Note: Podman may add 'localhost/' prefix to the image name
podman build -t flask-web:1.0 .

# Verify the image was built (check with or without localhost/ prefix)
podman images | grep flask-web

# Save the image in OCI format
# Use the image name as shown in 'podman images' output
podman save --format oci-archive -o /root/flask-web-oci.tar flask-web:1.0

# Alternative if podman added localhost/ prefix:
# podman save --format oci-archive -o /root/flask-web-oci.tar localhost/flask-web:1.0

# Verify the OCI archive exists
ls -lh /root/flask-web-oci.tar

# Verify it's a valid tar file
file /root/flask-web-oci.tar

# Test the image works (optional)
podman run -d --name test-flask -p 8080:8080 flask-web:1.0
sleep 3
curl http://localhost:8080
podman stop test-flask
podman rm test-flask
```

**Alternative: Using Containerfile explicitly**
```bash
# Build with explicit Containerfile
podman build -f Containerfile -t flask-web:1.0 .

# Save in OCI format
podman save --format oci-archive -o /root/flask-web-oci.tar flask-web:1.0
```

**Verification Commands:**
```bash
# Check image exists (may show with or without localhost/ prefix)
podman image ls | grep flask-web

# Check OCI archive file details
file /root/flask-web-oci.tar
ls -lh /root/flask-web-oci.tar

# Verify OCI structure
tar -tf /root/flask-web-oci.tar | grep -E "(oci-layout|index.json)"

# Test loading the OCI archive
podman load -i /root/flask-web-oci.tar

# Verify loaded image
podman images | grep flask-web
```

**Test functionality after loading:**
```bash
# Remove original image
podman rmi flask-web:1.0

# Load from OCI archive
podman load -i /root/flask-web-oci.tar

# Run and test
podman run --rm -p 8081:8080 flask-web:1.0 &
sleep 3
curl http://localhost:8081
pkill -f podman
```

</details>


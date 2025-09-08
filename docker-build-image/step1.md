# 🐳 CKAD: Build and Export Docker Image

Your company's production environment is air-gapped and cannot pull images directly from Docker registries. 

You need to build a Docker image and export it as a tar file for manual transfer to production servers.

## 📋 Task Requirements

There is a Node.js application ready at **`/opt/course/docker/`** with:
- **`app.js`** - Simple HTTP server application  
- **`package.json`** - NPM package configuration
- **`Dockerfile`** - Production-ready container definition
- **`exports/`** - Directory for saving the exported image


> **Important**: The production team specifically requested the tag `myapp:2.1` and filename `myapp-v2.1.tar`

---

## 💡 Complete Solution

<details>
<summary>🔧 Click to view step-by-step solution</summary>

```bash
# Navigate to project directory
cd /opt/course/docker

# Build the Docker image
docker build -t myapp:2.1 .

# Export the image to tar file
docker save myapp:2.1 -o exports/myapp-v2.1.tar

# Verify the export file exists and is valid
ls -la exports/
file exports/myapp-v2.1.tar

# Test the original image works
docker run -d --name test-myapp -p 3000:3000 myapp:2.1

# Check if application responds
curl http://localhost:3000
# or
wget -q -O - http://localhost:3000

# Check container status
docker ps | grep myapp

# View application logs
docker logs test-myapp

# Stop and remove test container
docker stop test-myapp
docker rm test-myapp

# Test loading the exported image
docker rmi myapp:2.1  # Remove original
docker load -i exports/myapp-v2.1.tar  # Load from export

# Verify loaded image works
docker run --rm -p 3001:3000 myapp:2.1 &
sleep 2
curl http://localhost:3001
pkill -f "docker run"
```

**Verification Commands:**
```bash
# Check image exists
docker image ls myapp:2.1

# Check export file size
du -h exports/myapp-v2.1.tar

# List tar contents (optional)
docker load -i exports/myapp-v2.1.tar
```

</details>


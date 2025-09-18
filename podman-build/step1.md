# 🌌 Deploy BlackHole Wave Monitoring System

## 🎯 **Mission: Complete Container Deployment Pipeline**

Welcome to **BlackHole Wave Monitoring System** - a critical space observation platform that monitors cosmic events across multiple observation nodes.

You are a **DevOps Engineer** at **Quantum Space Observatory** tasked with deploying a new monitoring container across the distributed observation network.

---

## 🌌 **Mission Overview: BlackHole Wave Detector**

**Project:** BlackHole Wave Monitoring System v2.36  
**Maintainer:** Omkar Shelke  
**Company:** Killer Coda CKDA Practice  
**Deployment Target:** Multi-node observation network  


You need to build, save, transfer, and deploy the BlackHole Wave Monitoring container across the distributed observation network.

---

## 📋 **Mission Requirements**

### 🏗️ **Phase 1: Build Container Image**
- Build image from the provided `blackhole-project/Dockerfile`
- Tag as: `quantum.registry:8000/blackhole-wave:2.36`
- Verify image creation

### 💾 **Phase 2: Save in OCI Format**  
- Save container image using Podman
- Output filename: `blackhole-monitoring.tar`
- Use OCI-compliant format

### 📦 **Phase 3: Transfer to Node01**
- Copy the tar file into `node01:/tmp/` (`use scp command`)
- Maintain file integrity during transfer

### 🚀 **Phase 4: Deploy on node01**
- Load the OCI container image on node01 from `blackhole-monitoring.tar`
- Run container with name: `blackhole-monitoring`
- Verify container is operational

### 📊 **Phase 5: Monitor and Verify**
- Check container logs
- Confirm monitoring script is running
- Verify maintainer information appears

---

## 🛠️ **Getting Started**

Navigate to the project directory:
```bash
cd /root/blackhole-project
```

Examine the Dockerfile:
```bash
cat Dockerfile
```

---

## 💡 **Try the complete deployment yourself!**

<details><summary>🚀 Complete Solution (expand to view)</summary>

### **Phase 1: Build the Container Image**

Navigate to project directory and build:
```bash
cd /root/blackhole-project

# Build the container image
podman build -t quantum.registry:8000/blackhole-wave:2.36 .
```

Verify the image was built:
```bash
podman images | grep blackhole-wave
```

### **Phase 2: Save Image in OCI Format**

Save the image as a tar archive:
```bash
podman save --format oci-archive -o blackhole-monitoring.tar quantum.registry:8000/blackhole-wave:2.36
```

Verify the archive was created:
```bash
ls -lh blackhole-monitoring.tar
```

### **Phase 3: Transfer to Node01**

Copy the tar file to node01:
```bash
scp blackhole-monitoring.tar node01:/tmp/
```

Verify the file exists on node01:
```bash
ssh node01 "ls -lh /tmp/blackhole-monitoring.tar"
```

### **Phase 4: Load and Run Container on Node01**

Load the container image on node01:
```bash
ssh node01 "podman load -i /tmp/blackhole-monitoring.tar"
```

Verify the image was loaded:
```bash
ssh node01 "podman images | grep blackhole-wave"
```

Run the container:
```bash
ssh node01 "podman run -d --name blackhole-monitoring quantum.registry:8000/blackhole-wave:2.36"
```

### **Phase 5: Verify Deployment**

Check container status:
```bash
ssh node01 "podman ps | grep blackhole-monitoring"
```

Check container logs (you should see the monitoring output):
```bash
ssh node01 "podman logs blackhole-monitoring"
```

Monitor logs in real-time (optional):
```bash
ssh node01 "podman logs -f blackhole-monitoring"
```

Expected log output should show:
- Container startup message
- Maintainer: Omkar Shelke - Killer Coda CKDA Practice
- Incrementing counter every 10 seconds
- Timestamp for each log entry

### **Phase 6: Additional Verification Commands**

Check container details:
```bash
ssh node01 "podman inspect blackhole-monitoring"
```

View container resource usage:
```bash
ssh node01 "podman stats blackhole-monitoring --no-stream"
```

Check exposed ports:
```bash
ssh node01 "podman port blackhole-monitoring"
```

---

### **🔧 Troubleshooting Tips**

If the container fails to start:
```bash
# Check container exit status
ssh node01 "podman ps -a | grep blackhole-monitoring"

# View detailed logs
ssh node01 "podman logs blackhole-monitoring"

# Inspect container configuration
ssh node01 "podman inspect blackhole-monitoring"
```

If the image build fails:
```bash
# Check Dockerfile syntax
cat Dockerfile

# Build with verbose output
podman build -t quantum.registry:8000/blackhole-wave:2.36 . --log-level debug
```

---

### **✅ Success Criteria**

Your deployment is successful when:
- ✅ Container image built successfully  
- ✅ Image saved as blackhole-monitoring.tar
- ✅ File transferred to node01 
- ✅ Container running on node01 with name "blackhole-monitoring"
- ✅ Logs show monitoring script output
- ✅ Maintainer information visible in logs
- ✅ Counter incrementing every 10 seconds

</details>


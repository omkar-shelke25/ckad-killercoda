# ❓ Question

Your production team **RetailCo** is building the *Analytics API* service.  
They want to package it as a container image and deliver it in two formats.

👉 Using **Docker Buildx**, build the image from `/opt/course/21/workdir` and export it as:

1. 🐳 Docker archive saved to:  
   `/opt/course/21/docker/myapp-docker.tar`

2. 🌐 OCI archive saved to:  
   `/opt/course/21/oci/myapp-oci.tar`

> Please check the `docker buildx version`. If it is not available, wait for 1 minute to install Docker Buildx.

## 💡 Complete Solution

<details>
<summary>🔍 Click to view full YAML solution</summary>

```bash
docker buildx build -t my-app:v1 .  --output type=docker,dest=/opt/course/21/docker/myapp-docker.tar
docker buildx build -t my-app:v1 .  --output type=oci,dest=/opt/course/21/oci/myapp-oci.tar
```
 
- `docker load -i /opt/course/21/docker/myapp-docker.tar`  
- `tar -tf /opt/course/21/oci/myapp-oci.tar | grep oci-layout`

<details>


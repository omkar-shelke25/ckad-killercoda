# ❓ Question

Your production team **RetailCo** is building the *Analytics API* service.  
They want to package it as a container image and deliver it in two formats.

👉 Using **Docker Buildx**, build the image from `/opt/course/21/workdir` and export it as:

1. 🐳 Docker archive saved to:  
   `/opt/course/21/docker/myapp-docker.tar`

2. 🌐 OCI archive saved to:  
   `/opt/course/21/oci/myapp-oci.tar`

> You can use any name and tag for the image (eg `retailco/analytics-api:v1`) during the build.

> Please check the `docker buildx version`. If it is not available, wait for 1 minute to install Docker Buildx.

## 💡 Complete Solution

<details>
<summary>🔍 Click to view full solution</summary>

##### Build Images 
   
```bash
# build the image from /opt/course/21/workdir
cd /opt/course/21/workdir
```

```bash
docker buildx build -t retailco/analytics-api:v1 . --output type=docker,dest=/opt/course/21/docker/myapp-docker.tar
docker buildx build -t retailco/analytics-api:v2 . --output type=oci,dest=/opt/course/21/oci/myapp-oci.tar
```
Here’s the verification commands :

**For Docker tarball (type=docker):**

```bash
docker load -i /opt/course/21/docker/myapp-docker.tar
docker images | grep retailco/analytics-api
```

**For OCI tarball (type=oci):**

```bash
tar -tf /opt/course/21/oci/myapp-oci.tar | head
```

</details>

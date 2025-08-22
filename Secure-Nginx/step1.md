# Nginx Deployment with NET_BIND_SERVICE

A Deployment needs to run Nginx serving HTTP on port 80 inside the `web` namespace.  
The application team should not run containers as root, but the Pods must still be able to bind to port 80.

## Task

Create a Deployment named **nginx-web** that:
- Runs **2 replicas** using the image **nginx:1.25-alpine**.
- Exposes **container port 80**.
- Ensures the container runs as **UID 101**.
- **Prevents privilege escalation** and **runs as non-root**.
- Grants **only** the `NET_BIND_SERVICE` capability so the container can bind to port 80.
- Verify that the Pods reach **Ready** state.

---

## (Optional) Example Solution

<details>
<summary>Click to view YAML</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-web
  namespace: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-web
  template:
    metadata:
      labels:
        app: nginx-web
    spec:
      securityContext:
        runAsUser: 101
        runAsNonRoot: true
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
            add: ["NET_BIND_SERVICE"]

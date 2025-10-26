## 🧩 **CKAD: Configure a Single Ingress for Path Routing**

You are working in a Kubernetes cluster where the following Deployments are already running in the **`streaming`** namespace:

```
streaming   api-server
streaming   video-processor
```

Each Deployment has an associated Service:

* **`api-service`** (port 80 → container port 5678)
* **`video-service`** (port 80 → container port 5678)

---

### **Task**

Create an **Ingress** resource named **`app-ingress`** in the **`streaming`** namespace that routes traffic for host **`streams.local`** as follows:

* Path `/api` → Service **`api-service`** on port **80**
* Path `/video` → Service **`video-service`** on port **80**

Both rules must use **`pathType: Prefix`**, and the Ingress should use the **`traefik`** Ingress class.

---

### **Additional Configuration**

1. Add the node IP in your `/etc/hosts` file:

   ```
   <NODE_IP>  streams.local
   ```

   Example:

   ```
   172.30.2.2  streams.local
   ```

2. Verify that the Ingress routes work through the Traefik NodePort (**30099**):

   ```bash
   curl http://streams.local:30099/api
   curl http://streams.local:30099/video
   ```

**Expected Output:**

```
hello-from-api
hello-from-video
```

-


---

## Try it yourself first!

✅ Solution (expand to view)
<details><summary>YAML</summary></summary>


```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: streaming
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /video
        pathType: Prefix
        backend:
          service:
            name: video-service
            port:
              number: 80

```

</details>

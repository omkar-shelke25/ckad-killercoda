# Configure a Single Ingress for Path Routing

## Objective
Create a single Ingress named **`app-ingress`** in namespace **`streaming`** to route traffic for host **`app.example.com`**:
- `/api`   → **api-service:80**
- `/video` → **video-service:80**
Both rules must use **`pathType: Prefix`**.

> Note: You don't need a running Ingress controller for this task's verification — we validate the Ingress spec.

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

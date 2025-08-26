# Configure Ingress to Serve /app but Forward as / (rewrite)

## Real-life scenario
A legacy app only serves **`/`**. You must expose it at **`legacy.example.com/app`** without touching the image or code. Use an **Ingress** to match `/app` and **rewrite** the path to `/` so the backend still receives root.

## Requirements
- Namespace: **legacy**
- Ingress: **`legacy-ingress`**
- Host: **`legacy.example.com`**
- Route: **`/app`** → **legacy-svc:80**
- Add annotation to **rewrite** the target path to `/` so the backend receives `/` (not `/app`).

> Note: Different Ingress controllers implement rewrites slightly differently. This task validates the **spec** and the presence of the **rewrite annotation** commonly used by NGINX Ingress. No live controller is required to pass verification.

---

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: legacy-ingress
  namespace: legacy
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: "/"
spec:
  rules:
  - host: legacy.example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: legacy-svc
            port:
              number: 80
```

</details>

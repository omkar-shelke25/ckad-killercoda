# Configure an Ingress with a Default Backend (Catch-all)

Product wants **`main.example.com`** to serve the main site, but any **unknown host/path** should render the custom error page (friendly 404). You’ll configure one Ingress to route the known host to **`main-site-svc`** and **everything else** to **`error-page-svc`** as a **default backend**.

## Requirements
- Namespace: **main**
- Create an Ingress **`site-ingress`**
- Use **`ingressClassName: nginx`**
- Add annotation: `nginx.ingress.kubernetes.io/rewrite-target: "/"`
- Rule: **host** `main.example.com` → **`main-site-svc:80`**
- **Default backend** (catch-all): **`error-page-svc:80`**



---

## Try it yourself first!
  
<details><summary>✅ Solution (expand to view)</summary>
  
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: site-ingress
  namespace: main
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: "/"
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: error-page-svc
      port:
        number: 80
  rules:
  - host: main.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: main-site-svc
            port:
              number: 80
```
</details> 

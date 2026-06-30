# Completed

You configured the Hero Registration Portal Ingress with TLS termination and path-based routing.

## Your Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hero-reg-ingress
  namespace: class-1a
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - heroes.ua-academy.com
    secretName: ua-heroes-tls
  rules:
  - host: heroes.ua-academy.com
    http:
      paths:
      - path: /register
        pathType: Prefix
        backend:
          service:
            name: register-service
            port:
              number: 80
      - path: /verify
        pathType: Prefix
        backend:
          service:
            name: verify-service
            port:
              number: 80
```

## Traffic Flow

```
HTTPS request: https://heroes.ua-academy.com/register
       │
       ▼
Ingress Controller (NGINX)
       │
       ▼
TLS termination (secret: ua-heroes-tls)
       │
       ▼
Ingress: hero-reg-ingress
       │
       ▼
Path match: /register
       │
       ▼
Service: register-service:80
       │
       ▼
Pods: register-service
```

## Key Concepts

**Ingress resource** — defines routing rules for external HTTP/HTTPS traffic into the cluster.

**TLS termination** — the Ingress Controller decrypts HTTPS at the edge using the cert/key in the TLS secret, then forwards plain HTTP to backend Services. This means backend Services don't need their own certificates.

**Path-based routing** — a single host can route to multiple backend Services based on the URL path, using `pathType: Prefix` to match a path and everything under it.

**`ingressClassName`** — tells Kubernetes which Ingress Controller should handle this resource. Without it (or with the wrong value), the controller won't act on it even if everything else is correct.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/Ingress-TLS)**

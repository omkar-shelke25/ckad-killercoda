# CKAD Scenario: Ingress with Default Backend

### Reference Docs
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Default backend](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend)
- [Ingress controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

---

## Context

Namespace `main` has two backend Services pre-deployed:

| Service | What it serves |
|---|---|
| `main-site-svc` (port 80) | The main marketing site |
| `error-page-svc` (port 80) | A custom error/catch-all page |

An nginx Ingress Controller is already installed and running in namespace `ingress-nginx`.

## Task

Create an Ingress named **`site-ingress`** in namespace `main` that:

1. Uses `ingressClassName: nginx`
2. Adds the annotation `nginx.ingress.kubernetes.io/rewrite-target: /`
3. Routes host **`main.example.com`**, path **`/`**, to **`main-site-svc:80`** (`pathType: Prefix`)
4. Sets **`error-page-svc:80`** as the **default backend** (catches all unmatched hosts and paths)

> The Ingress name and namespace must match exactly — verification checks for `site-ingress` in `main`.

---

## Test Manually

Find the NodePort the Ingress Controller is listening on:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller
# Look for the NodePort in the PORT(S) column, e.g. 80:30080/TCP
```

Then test routing:

```bash
# Store the NodePort in a variable (replace 30080 with the actual port)
PORT=30080

# Should return the main site response
curl http://main.example.com:$PORT/

# Should return the error-page response (host does not match any rule)
curl -H "Host: other.example.com" http://main.example.com:$PORT/
```

`main.example.com` is already resolved to the node IP in `/etc/hosts`, so you can use the hostname directly.

---

## Solution

Try it yourself first, then expand below if you need help.

<details>
<summary>Click to view Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: site-ingress
  namespace: main
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
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

**Apply it:**

```bash
kubectl apply -f site-ingress.yaml
```

**Key concepts:**

- **`spec.rules`** — Host-based routing rules. A request for `main.example.com` on path `/` goes to `main-site-svc`.
- **`spec.defaultBackend`** — The fallback for any request that does not match any rule. Any host other than `main.example.com`, or any unmatched path, is served by `error-page-svc`.
- **`rewrite-target: /`** — An nginx annotation that rewrites the matched path to `/` before forwarding to the backend.

**Verify the Ingress was created:**

```bash
kubectl -n main describe ingress site-ingress
```

</details>

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

An nginx Ingress Controller is running in namespace `ingress-nginx`, exposed via a **NodePort** Service.

## Task

Create an Ingress named **`site-ingress`** in namespace `main` that:

1. Uses `ingressClassName: nginx`
2. Adds the annotation `nginx.ingress.kubernetes.io/rewrite-target: /`
3. Routes host **`main.example.com`**, path **`/`**, to **`main-site-svc:80`** (`pathType: Prefix`)
4. Sets **`error-page-svc:80`** as the **default backend** (`spec.defaultBackend`) — the fallback for any request that does not match a defined rule

> The Ingress name and namespace must match exactly — verification checks for `site-ingress` in `main`.


> `spec.defaultBackend` is a Kubernetes Ingress field, not an nginx-specific annotation. It tells the controller which service to use as the fallback. Verification confirms this field is set correctly in the Ingress spec.


---

## Test Manually

Look up the NodePort the Ingress Controller is listening on:

```bash
PORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo "Ingress NodePort: $PORT"
```

`main.example.com` is already mapped to the node IP in `/etc/hosts`, so use it directly:

```bash
# Should return the main site response
curl http://main.example.com:$PORT/

# Should return the error-page response — path /notfound has no rule on main.example.com
curl -H "Host: main.example.com" http://main.example.com:$PORT/notfound
```

Confirm the controller picked up the Ingress and shows the default backend:

```bash
kubectl -n main describe ingress site-ingress
```

Look for the `Default backend:` field in the output — it should show `error-page-svc:80` with a resolved endpoint IP.


> The nginx Ingress Controller (v1.8.x) has a built-in catch-all server block that returns its own `404` for unmatched hosts before `spec.defaultBackend` is consulted. Sending a curl with an unknown `Host:` header through the NodePort will return nginx's own 404 page, not the `error-page-svc` response. The `spec.defaultBackend` field is still the correct and required way to declare the fallback — the controller acknowledges it and uses it for traffic that bypasses the catch-all (e.g. direct L4 connections without a Host header). Verification confirms the field is set correctly in the spec.


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
- **`spec.defaultBackend`** — The fallback declared in the Ingress spec. Any request that does not match a defined rule is intended to reach `error-page-svc`. The controller shows this in `kubectl describe ingress` under `Default backend:`.
- **`rewrite-target: /`** — Rewrites the matched path to `/` before forwarding to the backend. Applied to all paths matched by this Ingress.

**Verify the Ingress was created:**

```bash
kubectl -n main describe ingress site-ingress
```

</details>

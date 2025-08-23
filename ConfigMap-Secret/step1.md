# Externalize Runtime Configuration (ConfigMap + Secret → Env)

Your platform team requires application owners to externalize configuration. A service running in `apps` needs a database endpoint (non‑sensitive) and a third‑party API credential (sensitive). The application reads both **only via environment variables** at runtime.

## Task

Work only in the `apps` namespace:

- Provide the database endpoint via a **ConfigMap**.  
  Use a key name that reflects the property it sets and the production endpoint:
  `postgres://db.example.com:5432/production`  
  *Note: This URL contains no credentials; secrets are stored separately.*

- Provide the API credential via a **Secret**.  
  Use the value: `s3cr3t-ap1-k3y-f0r-pr0d`.

- Run a Pod that **remains running** using image `busybox:1.36`.  
  The application expects the variables to be named:
  - `DATABASE_URL` ← from the ConfigMap key for the database URL
  - `API_KEY`      ← from the Secret key for the API credential

- Do not mount files; consume **via env vars**.

### Acceptance criteria

- A **ConfigMap** exists that exposes the database URL under a property‑style key.
- A **Secret** exists that exposes the API key under a property‑style key.
- A Pod named `app-pod` in `apps`:
  - uses `busybox:1.36` and stays running,
  - has `DATABASE_URL` sourced from the ConfigMap key,
  - has `API_KEY` sourced from the Secret key.

---

## (Optional) Reference solution

<details>
<summary>Click to view YAML</summary>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: apps
data:
  database.url: postgres://db.example.com:5432/production
---
apiVersion: v1
kind: Secret
metadata:
  name: api-credentials
  namespace: apps
type: Opaque
stringData:
  api.key: s3cr3t-ap1-k3y-f0r-pr0d
---
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: apps
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh","-c","tail -f /dev/null"]
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.url
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-credentials
          key: api.key
```
</details> 

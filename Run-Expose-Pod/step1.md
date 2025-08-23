# Run & Expose — Imperative (CKAD)

## 🔹 Question (Weightage: 3)

A quick internal check is planned in the `ops` namespace. Platform wants a single-container web Pod (Apache httpd, Debian trixie) reachable via an in-cluster Service.

Conditions:
- Workload is a **Pod** (not a Deployment).
- Container image: `httpd:trixie`
- Container must **listen on port 80**
- Pod must carry label: `app=crypto-mining`
- The Pod must be **exposed** via a Service (ClusterIP is fine) on port **80**
- Service name should match the Pod name for easier discovery

The team prefers **imperative** creation (one-liner is acceptable), but YAML is allowed if you insist. Ensure the Pod actually becomes **Running** and the Service has a **ready endpoint** backing it.

### Your Tasks (in `ops`)
1. Create a **Pod** named `data-mining` with:
   - image `httpd:trixie`
   - container port `80`
   - label `app=crypto-mining`
2. Expose it with a **Service** named `data-mining` on port `80`.
3. Confirm the Service resolves to the Pod (endpoints present).

---

## ✅ Solution (expand)

<details>
<summary>Imperative (single command)</summary>

```bash
kubectl -n ops run data-mining \
  --image=httpd:trixie \
  --port=80 \
  --labels=app=crypto-mining \
  --expose \
  --restart=Never
```

</details>

<details> <summary>Imperative (two commands)</summary>

```bash
kubectl -n ops run data-mining \
  --image=httpd:trixie \
  --port=80 \
  --labels=app=crypto-mining \
  --restart=Never
```

```bash
kubectl -n ops expose pod data-mining \
  --port=80 \
  --name=data-mining
```
</details>

<details> <summary>YAML alternative</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-mining
  namespace: ops
  labels:
    app: crypto-mining
spec:
  containers:
  - name: httpd
    image: httpd:trixie
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: data-mining
  namespace: ops
spec:
  selector:
    app: crypto-mining
  ports:
  - port: 80
    targetPort: 80
```
</details>

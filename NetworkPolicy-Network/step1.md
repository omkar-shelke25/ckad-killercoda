# CKAD: NetworkPolicy — Restrict Redis Access

### 📚 Reference Docs
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy — ingress rules](https://kubernetes.io/docs/concepts/services-networking/network-policies/#ingress)
- [LabelSelector — matchLabels vs matchExpressions](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)

---

## 🧩 Scenario

In namespace **`jupiter`** there are three Deployments: **`app1`**, **`app2`**, and **`redis`**. All are exposed inside the cluster via Services.

Redis currently accepts connections from any Pod in the namespace. Your job is to lock it down so that only `app1` and `app2` can reach it.

---

## 📋 Tasks

Create a NetworkPolicy named **`np-redis`** in namespace `jupiter` that:

**1.** Targets Pods with label `app=redis`

**2.** Allows **ingress** only from Pods labeled `app=app1` or `app=app2`, on **TCP port 6379**

**3.** Blocks ingress from any other Pod (e.g. `test-pod`)

**4.** Allows **egress** for DNS lookups (`UDP/53` and `TCP/53`) so Redis Pods can still resolve cluster DNS

> 💡 You can express the `podSelector` using either `matchLabels` or `matchExpressions` — both are valid Kubernetes syntax and both are accepted by verification.

---

## ✅ Expected Result

```bash
APP1_POD=$(kubectl -n jupiter get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}')
TEST_POD=$(kubectl -n jupiter get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}')

# Should succeed
kubectl -n jupiter exec "$APP1_POD" -- timeout 5 sh -c 'echo > /dev/tcp/redis/6379' && echo "ALLOWED"

# Should fail / time out
kubectl -n jupiter exec "$TEST_POD" -- timeout 5 sh -c 'echo > /dev/tcp/redis/6379' && echo "ALLOWED" || echo "BLOCKED"
```

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

**Using matchLabels (simplest form):**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-redis
  namespace: jupiter
spec:
  podSelector:
    matchLabels:
      app: redis
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: app1
    - podSelector:
        matchLabels:
          app: app2
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

**Equivalent using matchExpressions:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-redis
  namespace: jupiter
spec:
  podSelector:
    matchExpressions:
    - key: app
      operator: In
      values: ["redis"]
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchExpressions:
        - key: app
          operator: In
          values: ["app1"]
    - podSelector:
        matchExpressions:
        - key: app
          operator: In
          values: ["app2"]
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

> ⚠️ Note: `app1` and `app2` are listed as **separate** `podSelector` entries inside `from`. This gives OR logic — traffic from either label is allowed. If you put both labels in a single `matchLabels` map, Kubernetes would require a Pod to have **both** labels simultaneously, which no Pod here has.

Apply and verify:

```bash
kubectl apply -f np-redis.yaml
kubectl -n jupiter describe networkpolicy np-redis
```

</details>

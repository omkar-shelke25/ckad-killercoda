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

> ⚠️ **Use `nc -zv`, not `/dev/tcp`, to test connectivity.**
> The Pods in this scenario run BusyBox, whose default shell (`ash`) does **not** support `/dev/tcp` redirection — that's a bash-only feature. Trying it will fail with `can't create /dev/tcp/...: nonexistent directory` even when your NetworkPolicy is correct. BusyBox does include `nc` (netcat), so use that instead.

```bash
APP1_POD=$(kubectl -n jupiter get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}')
TEST_POD=$(kubectl -n jupiter get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}')

# Should succeed — app1 is allowed
kubectl -n jupiter exec "$APP1_POD" -- nc -zv -w 5 redis 6379

# Should fail / time out — test-pod is blocked
kubectl -n jupiter exec "$TEST_POD" -- nc -zv -w 5 redis 6379
```

`nc -z` = scan-only mode (just checks if the port is open, sends no data). `-w 5` = 5 second timeout so a blocked connection fails fast instead of hanging.

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
  # Selects the Pods this policy applies TO — here, the Redis pods.
  podSelector:
    matchLabels:
      app: redis

  # We're controlling both inbound (who can reach redis) and
  # outbound (what redis can reach, i.e. DNS) traffic.
  policyTypes:
  - Ingress
  - Egress

  ingress:
  - from:
    # Two SEPARATE podSelector entries = OR logic.
    # "Allow traffic from (app=app1) OR (app=app2)"
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
  # No 'to' field means "to anywhere" — but only on these ports.
  # This is what allows DNS lookups to the cluster's DNS service.
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
    # matchExpressions form of "app=redis" — functionally identical
    # to matchLabels: {app: redis}, just more verbose syntax.
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

> ⚠️ **Why two separate `podSelector` entries, not one combined `matchLabels`?**
> `app1` and `app2` are listed as **separate** entries inside `from`. This gives OR logic — traffic from either label is allowed. If you instead put both labels into a single `matchLabels` map like `{app: app1, app: app2}` (which isn't even valid YAML for a map — duplicate keys), or tried `matchLabels: {app: app1}` combined with some other condition expecting `app2` too, Kubernetes would require a single Pod to carry **both** labels simultaneously — which no Pod in this scenario has. Each app1/app2 Pod only has ONE `app` label value.

**Apply and inspect:**

```bash
kubectl apply -f np-redis.yaml
kubectl -n jupiter describe networkpolicy np-redis
```

**Test with nc (not /dev/tcp — see warning above):**

```bash
APP1_POD=$(kubectl -n jupiter get pods -l app=app1 -o jsonpath='{.items[0].metadata.name}')
APP2_POD=$(kubectl -n jupiter get pods -l app=app2 -o jsonpath='{.items[0].metadata.name}')
TEST_POD=$(kubectl -n jupiter get pods -l app=test-pod -o jsonpath='{.items[0].metadata.name}')

# Both should succeed
kubectl -n jupiter exec "$APP1_POD" -- nc -zv -w 5 redis 6379
kubectl -n jupiter exec "$APP2_POD" -- nc -zv -w 5 redis 6379

# Should fail / time out
kubectl -n jupiter exec "$TEST_POD" -- nc -zv -w 5 redis 6379
```

</details>

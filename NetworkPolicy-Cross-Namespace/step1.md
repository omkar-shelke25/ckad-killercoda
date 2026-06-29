# CKAD: NetworkPolicy — Allow Cross-Namespace Egress to a Specific Pod

### 📚 Reference Docs
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy — egress rules](https://kubernetes.io/docs/concepts/services-networking/network-policies/#egress)

---

## 🧩 Scenario

Two namespaces are pre-configured with a **default-deny-all** NetworkPolicy. The `source-pod` in `netpol-demo9` needs to reach the `target-pod` in `external-ns` on TCP port 80 — but nothing else.

Your job is to create one NetworkPolicy that opens exactly that egress path.

**Pre-existing resources (do not modify):**

| Namespace | Resource | Label |
|---|---|---|
| `netpol-demo9` | Pod `source-pod` | `app=source` |
| `external-ns` | Pod `target-pod` | `app=target` |
| `external-ns` | Service `target-svc` | port 80 |

> ⚠️ Do not change or delete any pre-existing NetworkPolicies.

---

## 📋 Tasks

**1.** Create a NetworkPolicy named **`external-target`** in namespace **`netpol-demo9`** with:
- `podSelector`: select pods with label `app=source`
- `policyTypes`: `[Egress]`
- `egress` rule that allows traffic **only** to:
  - Namespace `external-ns` (match by `kubernetes.io/metadata.name: external-ns`)
  - Pods with label `app=target`
  - Protocol: `TCP`, Port: `80`

**2.** Verify connectivity from `source-pod`:

```bash
kubectl exec source-pod -n netpol-demo9 -- \
  wget -qO- http://target-svc.external-ns:80
```

Expected: nginx HTML output. If it times out, the NetworkPolicy is not correct.

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

### 💡 Key Concept — Selector Combinations

Understanding how `namespaceSelector` and `podSelector` combine in a `to` rule is critical here:

| Form | What it means | Access granted to |
|---|---|---|
| `namespaceSelector` only | Match by namespace | All pods in that namespace |
| `podSelector` only | Match by pod label | Pods with that label in the **same** namespace |
| Both in the **same** `to` entry | AND logic | Pods with that label **in** the matching namespace |
| Both as **separate** `to` entries | OR logic | Either condition matches |

For this task you need **AND logic** — both selectors must be in the **same** `to` entry.

---

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: external-target
  namespace: netpol-demo9
spec:
  podSelector:
    matchLabels:
      app: source
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: external-ns
      podSelector:
        matchLabels:
          app: target
    ports:
    - protocol: TCP
      port: 80
```

Apply it:

```bash
kubectl apply -f external-target.yaml
```

Test it:

```bash
kubectl exec source-pod -n netpol-demo9 -- \
  wget -qO- --timeout=5 http://target-svc.external-ns:80
```

</details>

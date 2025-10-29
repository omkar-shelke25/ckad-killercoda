
📘 [Network Policies | Kubernetes Docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### CKAD: Allow Cross-Namespace Egress to Target Pod (TCP/80)

Two namespaces exist:

* `netpol-demo9` with a Pod named `source-pod` (label `app=source`)
* `external-ns` with a Pod named `target-pod` (label `app=target`)

Create a NetworkPolicy named `external-target` in the `netpol-demo9` namespace.
The policy should select only the Pod with label `app=source` and have `policyTypes: [Egress]`.
Allow egress traffic from the selected Pod **only** to Pods in the `external-ns` namespace with label `app=target` on **TCP port `80`**.


> Use the `wget` command to test communication.
> Please don't change the pre-existing policy.

---

#### ✅ Solution (expand to view)

<details>
<summary>Show YAML</summary>

| Case | Selector Used                       | Access Granted To                                                                      |
| ---- | ----------------------------------- | -------------------------------------------------------------------------------------- |
| 1️⃣  | Only `namespaceSelector`            | All pods in that namespace                                                             |
| 2️⃣  | Only `podSelector`                  | Pods with those labels in **same namespace** (since `podSelector` is namespace-scoped) |
| 3️⃣  | `namespaceSelector` + `podSelector` | Pods matching that label **within the matching namespace(s)**                          |

  
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
</details>

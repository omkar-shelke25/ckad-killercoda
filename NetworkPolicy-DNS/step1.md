# 🧩 **CKAD Scenario: DNS-Only Egress NetworkPolicy**

---

### 🧭 **Context**

A Pod named **`isolated`** exists in the namespace **`netpol-demo2`**.
Your organization’s security policy requires this Pod to be **completely isolated** from the cluster network.

The Pod must:

* 🚫 **Not accept any incoming traffic** (Ingress blocked).
* 🚫 **Not send any outgoing traffic** (Egress blocked).
* 🌐 **Only be allowed to perform DNS lookups** (UDP port `53`) to any destination.



---

## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

**Using YAML**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-except-dns
  namespace: netpol-demo2
spec:
  podSelector:
    matchLabels:
      app: isolated
  policyTypes:
  - Ingress
  - Egress
  ingress: []   # default deny all ingress
  egress:
  - ports:
    - protocol: UDP
      port: 53  # allow DNS only
```
</details>

# DNS-Only Egress NetworkPolicy

## **Question (Weightage: 4)**

A Pod named `isolated` exists in the `netpol-demo2` namespace.  
Security requires that the Pod **must not accept any incoming traffic** and **must not send any traffic**, **except** it should be allowed to perform **DNS lookups** (UDP port **53**) to any destination.

### **Task**

Create a NetworkPolicy named `deny-all-except-dns` in the `netpol-demo2` namespace that:

- Targets **only** the `isolated` Pod (use its label `app=isolated`).
- **Denies all ingress** to that Pod.
- **Denies all egress** from that Pod **except** UDP port **53** (DNS) to any destination.
- Explicitly sets `policyTypes` to include **Ingress** and **Egress**.

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

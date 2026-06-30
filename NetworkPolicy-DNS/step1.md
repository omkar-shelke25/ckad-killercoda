# CKAD Scenario: DNS-Only Egress NetworkPolicy

### Reference Docs
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Default deny all egress traffic](https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-egress-traffic)

---

## Context

A Pod named **`isolated`** (label `app=isolated`) exists in namespace **`netpol-demo2`**.

Security policy requires this Pod to be fully isolated from the cluster network, with one exception: it must still be able to resolve DNS.

## Task

Create a NetworkPolicy named **`deny-all-except-dns`** in namespace `netpol-demo2` that:

1. Targets the Pod labeled `app=isolated`
2. Blocks **all** incoming traffic (no ingress rules)
3. Blocks **all** outgoing traffic **except** DNS lookups on **UDP port 53**

> The policy name matters — verification checks for `deny-all-except-dns` specifically.

---

## Quick Reference: How `policyTypes` and rules interact

| `policyTypes` includes | Rules defined | Result |
|---|---|---|
| Not listed | — | Traffic in that direction is fully **allowed** |
| Listed | No rules (`[]` or omitted) | Traffic in that direction is fully **denied** |
| Listed | Rules present | Only matching traffic is **allowed**, rest denied |

So: list both `Ingress` and `Egress`, leave `ingress` empty to deny it completely, and give `egress` exactly one rule for UDP/53.

---

## Solution

Try it yourself first.

<details>
<summary>Click to view Solution</summary>

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
  ingress: []   # no rules = all ingress denied
  egress:
  - ports:
    - protocol: UDP
      port: 53  # only DNS allowed out
```

Apply it:

```bash
kubectl apply -f deny-all-except-dns.yaml
kubectl -n netpol-demo2 describe networkpolicy deny-all-except-dns
```

</details>

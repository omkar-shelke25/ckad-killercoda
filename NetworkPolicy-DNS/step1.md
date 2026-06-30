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

## Solution

Try it yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Step 1: Write the NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-except-dns
  namespace: netpol-demo2
spec:
  # Selects the Pod(s) this policy applies TO.
  podSelector:
    matchLabels:
      app: isolated

  # We're controlling both inbound and outbound traffic for this Pod.
  policyTypes:
  - Ingress
  - Egress

  # Listed in policyTypes but no rules underneath = everything in
  # this direction is denied. This is what makes ingress fully blocked.
  ingress: []

  # Listed in policyTypes WITH one rule = only traffic matching that
  # rule is allowed, everything else is denied.
  egress:
  - ports:
    - protocol: UDP
      port: 53   # DNS lookups only — no 'to:' means any destination
```

> **Why `ingress: []` and not just omitting `ingress` entirely?**
> Both behave the same way once `Ingress` is in `policyTypes` — an empty list and an omitted key both mean "no rules," so all ingress is denied either way. Writing `ingress: []` explicitly just makes the intent clear to anyone reading the policy later.

> **Why no `to:` under the egress rule?**
> Omitting `to:` means the rule applies to traffic going to *any* destination, restricted only by the `ports:` filter. Since we only care about restricting the port (UDP/53), not the destination, this correctly allows DNS lookups to reach the cluster's DNS service without needing to know its Pod IP or labels.

### Step 2: Apply it

```bash
kubectl apply -f deny-all-except-dns.yaml
```

### Step 3: Inspect it

```bash
kubectl -n netpol-demo2 describe networkpolicy deny-all-except-dns
```

You should see:
- **Allowing ingress traffic:** none (no rules listed)
- **Allowing egress traffic:** one rule, UDP port 53, to any destination

### Step 4: Test it

DNS should still resolve from inside the Pod:

```bash
kubectl -n netpol-demo2 exec isolated -- nslookup kubernetes.default
```

This should succeed. Any other outbound connection (e.g. to another Pod or external host) or any inbound connection to `isolated` should now fail or time out, confirming the lockdown is working as intended.

</details>

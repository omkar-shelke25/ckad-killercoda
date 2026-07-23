# CKAD Scenario: Egress NetworkPolicy with DNS Exception

### Reference Docs
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [The NetworkPolicy resource](https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource)

---

## Context

Namespace `venus` contains two Deployments and their Services:

- **`api`** — an HTTP server listening on port **2222**
- **`frontend`** — a busybox Pod used to test outbound connectivity

## Task

Create a NetworkPolicy named **`np1`** in namespace `venus` that:

1. Targets Pods with label `app=frontend`
2. Sets policy type to **Egress** only
3. Allows outgoing TCP traffic to Pods labeled `app=api` on port **2222**
4. Allows outgoing DNS traffic on **UDP/53** and **TCP/53** to any destination
5. Blocks all other outbound traffic (including internet access)

> The policy name matters — verification checks for `np1` exactly.

---

## Verify Manually

Open a shell inside the frontend Pod and test connectivity:

```bash
kubectl -n venus exec -it deploy/frontend -- sh
```

Inside the Pod, run:

```bash
# Should succeed — DNS is allowed
nslookup api.venus.svc.cluster.local

# Should succeed — api:2222 is allowed
wget -qO- --timeout=5 http://api:2222

# Should be blocked — external traffic is not allowed
wget -qO- --timeout=5 http://www.google.com
```

---

## Solution

Try it yourself first, then expand below if you need help.

<details>
<summary>Click to view Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: venus
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 2222
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

**Why two separate egress rules?**

- **Rule 1** — `to: app=api` + `ports: TCP/2222`: Allows TCP connections to `api` Pods on port 2222 only.
- **Rule 2** — `ports: UDP/53 + TCP/53` with no `to:` restriction: Allows DNS queries to any destination (required for CoreDNS to resolve service names).

A Pod must match at least one rule for traffic to be permitted. Everything else is silently dropped.

**Apply it:**

```bash
kubectl apply -f np1.yaml
```

**Inspect it:**

```bash
kubectl -n venus describe networkpolicy np1
```

You should see egress rules for TCP/2222 to app=api, and UDP+TCP/53 to anywhere.

</details>

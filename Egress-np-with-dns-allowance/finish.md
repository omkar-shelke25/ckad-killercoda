## Completed: Egress NetworkPolicy with DNS Exception

### Traffic summary

| Destination | Port | Result |
|---|---|---|
| `api` Pods | TCP/2222 | Allowed |
| CoreDNS | UDP/53, TCP/53 | Allowed |
| Any other destination | any | Blocked |

### What you practised

- Writing an Egress-only NetworkPolicy
- Combining a pod-targeted rule with an open DNS rule in the same policy
- Understanding why DNS needs a separate egress rule with no `to:` restriction

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/Egress-np-with-dns-allowance)**


Well done — you've restricted frontend egress to exactly what is needed, without breaking DNS.

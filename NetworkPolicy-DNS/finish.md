# 🎉 Completed

You implemented a strict default-deny NetworkPolicy for a sensitive Pod, fully isolating it from network traffic except for DNS.

```
NetworkPolicy: deny-all-except-dns
Namespace: netpol-demo2
├── podSelector:  app=isolated
├── policyTypes:  [Ingress, Egress]
├── ingress:      [] (all denied)
└── egress:
    └── ports: UDP/53 only (DNS)
```

## ✅ What You Accomplished

- 🚫 Denied all ingress traffic to the `isolated` Pod
- 🚫 Denied all egress traffic except DNS (UDP/53)
- 🌐 Verified DNS resolution still works under a zero-trust policy

## 💡 Key Takeaway

When a direction is listed in `policyTypes` but given no rules, it's fully denied — that's what makes `ingress: []` a default-deny. Egress with a single UDP/53 rule and no `to:` restriction allows DNS lookups to any destination while blocking everything else.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/NetworkPolicy-DNS)**

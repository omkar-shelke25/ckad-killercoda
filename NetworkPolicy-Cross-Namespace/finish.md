# 🎉 Completed

You created a precise NetworkPolicy allowing egress from `source-pod` in `netpol-demo9` to `target-pod` in `external-ns` on TCP/80.

## What You Built

```
NetworkPolicy: external-target
Namespace: netpol-demo9
├── podSelector:       app=source
├── policyTypes:       [Egress]
└── egress rule:
    ├── to[0].namespaceSelector: kubernetes.io/metadata.name=external-ns
    ├── to[0].podSelector:       app=target
    └── ports: TCP/80
```

## What You Accomplished

- ✅ Created NetworkPolicy `external-target` in `netpol-demo9`
- ✅ Egress allowed only to `external-ns`/`app=target` on TCP/80
- ✅ All other egress from `source-pod` remains blocked
- ✅ Live connectivity verified via `wget` to `target-svc.external-ns:80`

## Key Takeaways

- Use `namespaceSelector` + `podSelector` in the **same** `to` entry for AND logic — both conditions must match
- The label `kubernetes.io/metadata.name: <ns>` is the reliable way to match a namespace by name
- Always pair specific-allow policies with a `default-deny-all` for proper least-privilege egress control

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/NetworkPolicy-Cross-Namespace)**

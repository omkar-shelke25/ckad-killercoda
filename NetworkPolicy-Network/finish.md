# 🎉 Completed

You successfully restricted access to Redis using a NetworkPolicy.

## What You Built

```
NetworkPolicy: np-redis
Namespace: jupiter
├── podSelector:  app=redis
├── policyTypes:  [Ingress, Egress]
├── ingress:
│   ├── from: app=app1 OR app=app2
│   └── ports: TCP/6379
└── egress:
    └── ports: UDP/53, TCP/53 (DNS)
```

## What You Accomplished

- ✅ Created NetworkPolicy `np-redis` restricting incoming connections to Redis
- ✅ Allowed only `app1` and `app2` to connect to Redis on TCP port 6379
- ✅ Blocked all other Pods (e.g. `test-pod`) from connecting to Redis
- ✅ Preserved DNS resolution (UDP/TCP port 53) for Redis Pods

## Key Takeaway

Listing `app1` and `app2` as **separate** `podSelector` entries inside `from` gives OR logic — either label is allowed. Combining both labels into a single `matchLabels` map would instead require both labels on the same Pod, which doesn't match your setup.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/NetworkPolicy-Network)**

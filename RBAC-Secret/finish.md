# ✅ Completed

You granted **read-only access to a single Secret** using `resourceNames` in a Role.

## What You Built

```
Namespace: finance
├── Secret:         api-key-v2
├── ServiceAccount: specific-secret-reader-sa
├── Role:           single-secret-getter-role
│   └── rules:
│       apiGroups: [""]
│       resources: ["secrets"]
│       resourceNames: ["api-key-v2"]
│       verbs: ["get"]
└── RoleBinding:    single-secret-getter-binding
    └── specific-secret-reader-sa → single-secret-getter-role
```

## What You Accomplished

- ✅ Created Secret `api-key-v2`
- ✅ Created ServiceAccount `specific-secret-reader-sa`
- ✅ Created Role `single-secret-getter-role` with `resourceNames` restriction
- ✅ Bound the Role via RoleBinding `single-secret-getter-binding`
- ✅ SA can `get` only `secrets/api-key-v2` — nothing else

> 💡 `resourceNames` is the key CKAD concept here — it restricts access to a **specific named object** rather than the entire resource type.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/RBAC-Secret)**
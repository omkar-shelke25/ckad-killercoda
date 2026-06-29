# 🎉 Completed

You successfully configured RBAC for **both** deployments in the **`one-piece`** namespace!

## 🛡️ RBAC Best Practices

1. **Principle of Least Privilege** — only grant the verbs that are actually needed
2. **Use dedicated ServiceAccounts** — never rely on the `default` ServiceAccount for applications
3. **Prefer Roles over ClusterRoles** — namespace-scoped Roles limit the blast radius
4. **Audit regularly** — review who can do what with `kubectl auth can-i --list`
5. **Document your permissions** — leave comments explaining why each verb is granted

---

## 📊 What You Built

```
Namespace: one-piece
├── Deployments
│   ├── monkey-d-luffy   (serviceAccountName: thousand-sunny)
│   └── crew-monitor     (serviceAccountName: nami-navigator)
├── ServiceAccounts
│   ├── thousand-sunny
│   └── nami-navigator
├── Roles
│   ├── strawhat-role    (apps/deployments: get, list, watch)
│   └── navigator-role   (apps/deployments: get, list, watch)
└── RoleBindings
    ├── strawhat-rb      (strawhat-role  → thousand-sunny)
    └── navigator-rb     (navigator-role → nami-navigator)
```

Great work! You've mastered the fundamentals of Kubernetes RBAC — a critical skill for securing production clusters. 🚀

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken, unclear, or could be improved, please open an issue or submit a PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/monkey.d.luffy-rbac)**

Contributions and feedback are always welcome. 🙌

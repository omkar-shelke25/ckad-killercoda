# 🎉 Completed

You successfully converted the single **Pod** into a **Deployment** with **3 replicas** in the **`pluto`** namespace, applied container-level security settings, deleted the original Pod, and saved the manifest to:

`/opt/course/9/holy-api-deployment.yaml`

---

## 🛡️ What You Practised

- Converting a standalone Pod into a managed Deployment
- Setting `replicas` for high availability
- Applying `securityContext` at the **container level**
- Cleaning up replaced resources

---

## 📊 What You Built

```
Namespace: pluto
└── Deployment: holy-api
    ├── replicas: 3
    └── containers[0]
        ├── image: busybox:latest
        └── securityContext:
            ├── allowPrivilegeEscalation: false
            └── privileged: false
```

Great work! Understanding how to harden Pods with `securityContext` is a key CKAD exam skill. 🚀

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/convert-pod-to-deploy)**
# 🎉 Success!

You created a **ConfigMap** and exposed its keys as **environment variables** in a Pod, then verified the values at runtime.

## You accomplished
- ✅ Created `app-config` with `APP_MODE=production`, `APP_VERSION=1.0`
- ✅ Created `app-pod` using `nginx:1.29.0`
- ✅ Injected env vars using `envFrom` (or key-by-key with `configMapKeyRef`)
- ✅ Verified the values inside the running container

> Tip: Use `envFrom` for convenience when you want **all keys**, and `configMapKeyRef` for **explicit, per-key** control.

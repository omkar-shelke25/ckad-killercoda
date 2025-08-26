# 🎉 Done!

You created a **ConfigMap** and injected a **specific key** as an environment variable in a Pod, then verified it via **logs** in the `olly` namespace.

## You accomplished
- ✅ Created `message-config` with `message: Hello, Kubernetes`
- ✅ Created Pod `message-pod` (image `busybox:1.37.0`) that echoes `$MESSAGE`
- ✅ Mapped ConfigMap key `message` → env var `MESSAGE`
- ✅ Verified logs show the expected value

> Tip: Use `configMapKeyRef` to bind a **single key** to a **specific env var name**. Use `envFrom` when you want **all keys**.

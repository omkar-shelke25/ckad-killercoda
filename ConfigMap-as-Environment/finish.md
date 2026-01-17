# 🎉 Success!

You created a **ConfigMap** and exposed its keys as **environment variables** in a Pod, then verified the values at runtime.


## 💬 Have a doubt?

🔗 **Discord Link:**
[https://killercoda.com/discord](https://killercoda.com/discord)

## You accomplished
- ✅ Created `app-config` with `APP_MODE=production`, `APP_VERSION=1.0`
- ✅ Created `app-pod` using `nginx:1.29.0`
- ✅ Injected env vars using `envFrom` (or key-by-key with `configMapKeyRef`)
- ✅ Verified the values inside the running container

> ✅ Exam Tip
  - If the question says **mount as env variables** → use envFrom or configMapKeyRef.
  - If it says **app does not read env vars; config must be files** → use volume mount from ConfigMap.


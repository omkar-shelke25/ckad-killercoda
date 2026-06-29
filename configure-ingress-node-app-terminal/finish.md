## What You Accomplished

- ✅ Pod `multi-endpoint-app` running and serving both endpoints
- ✅ ClusterIP Service `multi-endpoint-service` routing port 80 to container port 3000
- ✅ Ingress `multi-endpoint-ingress` configured with two path rules
- ✅ DNS entry added to `/etc/hosts` pointing to the MetalLB-assigned IP
- ✅ `/terminal` endpoint verified via curl
- ✅ `/app` endpoint verified via curl

> `pathType: Prefix` means the rule matches the path and anything under it. The root path `/` returns 404 because no rule covers it — that is expected, not an error.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:
👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/configure-ingress-node-app-terminal)**

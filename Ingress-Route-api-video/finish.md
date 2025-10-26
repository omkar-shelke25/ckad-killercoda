# 🎉 Ingress Config Complete!

You created one Ingress for host **streams.local** that routes by path:

- `/api` → `api-service:80`
- `/video` → `video-service:80`

Both use `pathType: Prefix`.

---

### 🔁 Traffic Flow

Browser (streams.local)
        │
        ▼
   Traefik (NodePort :30099)
        │
        ▼
Ingress (app-ingress)
   ├── /api   → api-service → api-server Pod
   └── /video → video-service → video-processor Pod



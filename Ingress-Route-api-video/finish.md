# 🎉 Ingress Config Complete!

You created a single **Ingress** that routes by URL path on host **app.example.com**:
- `/api`   → `api-service:80`
- `/video` → `video-service:80`
with `pathType: Prefix` for both rules.

> Tip: For multi-path routing on one host, grouping under a single Ingress keeps your config tidy and avoids rule collisions.

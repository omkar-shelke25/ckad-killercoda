# 🎉 Ingress with Default Backend — Complete

You created a single **Ingress** in the `main` namespace that:
- Routes **`main.example.com`** → **`main-site-svc:80`**
- Uses a **default backend** (**`error-page-svc:80`**) for **all unmatched traffic**
- Sets **`ingressClassName: nginx`** and the rewrite annotation

> This catch-all pattern is ideal for custom 404s or “landing” pages that should respond to any unrecognized host/path.

# 🎉 Ingress Rewrite Complete

You configured **legacy-ingress** to expose the app at **/app** while the backend still receives requests as **/**.

## You accomplished
- ✅ Ingress **legacy-ingress** in namespace **legacy**
- ✅ Rule `legacy.example.com/app` → `legacy-svc:80`
- ✅ Added rewrite annotation so backend sees `/`


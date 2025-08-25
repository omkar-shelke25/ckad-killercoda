# 🎉 Completed — RBAC Pod Viewer

You implemented **least-privilege** access using namespace-scoped RBAC.

## ✅ You achieved
- ServiceAccount `pod-viewer-sa` in `dev-team-1`
- Role `pod-reader-role` (pods: get/list/watch)
- RoleBinding `pod-viewer-binding` (Role → SA)
- Verified:
  - ✅ Allowed in `dev-team-1`
  - ❌ Denied in `default`

🔐 **Key CKAD takeaway:** Prefer **Role/RoleBinding** for namespaced access and validate using `kubectl auth can-i`.

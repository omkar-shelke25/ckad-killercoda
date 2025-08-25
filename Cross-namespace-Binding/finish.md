# 🎉 Completed — Read Pod Logs Only

You implemented **strict, subresource-scoped RBAC** via a **cross-namespace RoleBinding**.

## ✅ You achieved
- SA `log-scraper-sa` in `default`
- Role `log-reader-role` in `app-prod` with **only**:
  - `resources: ["pods/log"]`
  - `verbs: ["get"]`
- RoleBinding `log-scraper-binding` in `app-prod`:
  - Role → `default/log-scraper-sa`
- Verified with impersonation:
  - ✅ `get` pods/log in `app-prod` → allowed
  - ❌ `get` pods (no subresource) → denied
  - ❌ `list` pods/log → denied
  - ❌ `get` pods/log in `default` → denied

🔐 **CKAD takeaway:** Use **subresource names** (e.g., `pods/log`) in RBAC rules for precise access, and specify the **subject’s namespace** when binding across namespaces.

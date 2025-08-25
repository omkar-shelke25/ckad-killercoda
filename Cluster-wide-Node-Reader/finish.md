# 🎉 Completed — Cluster-wide Node Reader

You granted a **namespaced ServiceAccount** cluster-wide **read-only** access to **Node** resources with **ClusterRole** and **ClusterRoleBinding**, and correctly attached the SA to a workload.

## ✅ You achieved
- SA `node-inspector-sa` in `monitoring`
- ClusterRole `node-reader-crole` (nodes: get, list)
- ClusterRoleBinding `node-inspector-crbinding` (ClusterRole → SA)
- Deployment `node-inspector-ui` running with `serviceAccountName: node-inspector-sa`
- Verified with impersonation:
  - ✅ `get`/`list` nodes → allowed
  - ❌ `delete` nodes → denied

🔐 **CKAD takeaway:** Cluster-scoped resources (like `nodes`) require **ClusterRole/ClusterRoleBinding**. Subjects (e.g., ServiceAccounts) are **namespaced**, so include the namespace in `subjects`. Always **attach the SA** to the workload to make the RBAC effective.

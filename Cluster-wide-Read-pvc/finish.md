# 🎉 Nice work!

You granted **cluster-wide read-only** access on storage resources to **sara.jones@example.com**.

## What you completed
- ✅ Created `ClusterRole` **storage-viewer-crole** with `get,list,watch` on:
  - `persistentvolumeclaims` (core API group)
  - `storageclasses` (`storage.k8s.io`)
- ✅ Created `ClusterRoleBinding` **sara-storage-viewer-crbinding** to bind the role to **User** `sara.jones@example.com`
- ✅ Verified with `kubectl auth can-i`

> Tip: For human users, subjects must use **kind: User** and are **not namespaced**.

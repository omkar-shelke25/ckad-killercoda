# Grant Cluster-wide Read-only Access to PVCs & StorageClasses

## Objective
A new DevOps engineer, **sara.jones@example.com**, has joined the team. Grant her **cluster-wide read-only** access to all **PersistentVolumeClaims (PVCs)** and **StorageClasses**.

## Requirements
- Create a **ClusterRole** named **`storage-viewer-crole`**.
  - Verbs: `get`, `list`, `watch`
  - Resources: 
    - `persistentvolumeclaims` in the **core** (empty) API group
    - `storageclasses` in the **storage.k8s.io** API group
- Create a **ClusterRoleBinding** named **`sara-storage-viewer-crbinding`**.
  - Bind the role to **User** `sara.jones@example.com`.

> Note: For a **human user**, the subject `kind` is **User** (not ServiceAccount), and it is **not namespaced**.

---

## ✅ Solution (expand to view)

<details>
<summary>Show commands (imperative)</summary>

```bash
# ClusterRole with correct API groups and verbs
kubectl create clusterrole storage-viewer-crole   --verb=get,list,watch   --resource=persistentvolumeclaims,storageclasses.storage.k8s.io

# Bind to the human user
kubectl create clusterrolebinding sara-storage-viewer-crbinding   --user=sara.jones@example.com   --clusterrole=storage-viewer-crole
```
</details>

<details> <summary>Show YAML (apply with kubectl apply -f)</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-viewer-crole
rules:
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sara-storage-viewer-crbinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: storage-viewer-crole
subjects:
  - kind: User
    name: sara.jones@example.com
    apiGroup: rbac.authorization.k8s.io
```
</details>



<details><summary>Verify manually</summary>
  
``bash
kubectl auth can-i list persistentvolumeclaims --as=sara.jones@example.com --all-namespaces
kubectl auth can-i list storageclasses --as=sara.jones@example.com
kubectl get pvc -A
kubectl get sc
```

</details>

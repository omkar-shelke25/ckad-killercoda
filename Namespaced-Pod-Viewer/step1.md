# 🧩 Task 1 — Role & RoleBinding for Pod Viewer (Weight: 5)

A developer workload in **`dev-team-1`** needs **read-only** access to Pod information within the **same** namespace.

> ℹ️ The namespace **`dev-team-1`** is already created by setup_script. Do **not** recreate it.

## ✅ Objective
Create a ServiceAccount and bind a namespaced Role that allows read-only access to **Pods** only within `dev-team-1`. Verify permissions are **denied** in other namespaces.

## 📋 Requirements
- Namespace: `dev-team-1` *(already exists)*
- ServiceAccount: `pod-viewer-sa` (in `dev-team-1`)
- Role: `pod-reader-role` (in `dev-team-1`)
  - `resources: ["pods"]`
  - `verbs: ["get","list","watch"]`
  - `apiGroups: [""]` (core)
- RoleBinding: `pod-viewer-binding` (in `dev-team-1`)
  - Bind `pod-reader-role` → `ServiceAccount dev-team-1/pod-viewer-sa`

---

## 💡 Hints (click to expand)
<details>
<summary>Imperative Way</summary>

```bash
kubectl create sa pod-viewer-sa -n dev-team-1

kubectl create role pod-reader-role \
  --resource=pods \
  --verb=get --verb=list --verb=watch \
  -n dev-team-1

kubectl create rolebinding pod-viewer-binding \
  --role=pod-reader-role \
  --serviceaccount=dev-team-1:pod-viewer-sa \
  -n dev-team-1
```
</details>

<details> <summary>Verify with impersonation</summary>
```bash
# Can read in dev-team-1
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev-team-1:pod-viewer-sa \
  -n dev-team-1

# Must be denied in default
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev-team-1:pod-viewer-sa \
  -n default
```
</details>

<details> <summary>YAML bundle</summary>
  
```yaml  
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-viewer-sa
  namespace: dev-team-1
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: dev-team-1
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-viewer-binding
  namespace: dev-team-1
subjects:
- kind: ServiceAccount
  name: pod-viewer-sa
  namespace: dev-team-1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader-role
```
</details>

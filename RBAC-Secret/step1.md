# CKAD: Grant Read-only Access to a Single Secret via `resourceNames`

## 📚 **Official Kubernetes Documentation**: 

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
- [RoleBinding and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [ServiceAccounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Managing Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)


## Objective
Create a ServiceAccount `specific-secret-reader-sa` in the **finance** namespace that can **only** `get` the Secret named **`api-key-v2`**, and **nothing else**.

## Requirements
- Create a Secret named **`api-key-v2`** in **finance** (content doesn't matter).
- Create a **ServiceAccount** named **`specific-secret-reader-sa`** in **finance**.
- Create a **Role** named **`single-secret-getter-role`** in **finance** that uses **`resourceNames`** to restrict `get` to only `api-key-v2` on resource **`secrets`** in API group `""` (core).
- Create a **RoleBinding** named **`single-secret-getter-binding`** to grant this role to that ServiceAccount.

> ℹ️ **Tip:** Use plural resource name `secrets`. Imperative short form accepts `secrets` or `secrets.` with group hints like `secrets` (core) — `cronjobs.batch` style is for non-core groups.

---

## ✅ Solution (expand to view)

<details><summary>Commands</summary>
  
```bash

# Secret
kubectl create secret generic api-key-v2 --from-literal=key=something -n finance

# ServiceAccount
kubectl create sa specific-secret-reader-sa -n finance

# Role (core group, plural 'secrets', restricted by resourceNames)
kubectl create role single-secret-getter-role -n finance \
  --verb=get \
  --resource=secrets \
  --resource-name=api-key-v2

# RoleBinding
kubectl create rolebinding single-secret-getter-binding -n finance \
  --role=single-secret-getter-role \
  --serviceaccount=finance:specific-secret-reader-sa
```
</details>

<details><summary>YAML</summary>

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-key-v2
  namespace: finance
type: Opaque
stringData:
  key: something
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: specific-secret-reader-sa
  namespace: finance
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: single-secret-getter-role
  namespace: finance
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["api-key-v2"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: single-secret-getter-binding
  namespace: finance
subjects:
  - kind: ServiceAccount
    name: specific-secret-reader-sa
    namespace: finance
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: single-secret-getter-role
```

</details>


<details><summary>Verify RBAC Permission</summary>
  
```bash
# Should succeed
kubectl auth can-i get secrets/api-key-v2 --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance

# Should fail
kubectl auth can-i get secrets/some-other-secret --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance

# Should also fail (no broad get on the whole resource)
kubectl auth can-i get secrets --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance
```
</details>


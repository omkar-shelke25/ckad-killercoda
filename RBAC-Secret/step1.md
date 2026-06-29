# CKAD: Grant Read-only Access to a Single Secret

### 📚 Reference Docs
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
- [RoleBinding and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

## 🧩 Scenario

The **finance** team stores a sensitive API key in a Kubernetes Secret. A new application needs to read **only that specific Secret** — nothing else.

Your job is to set up the RBAC so the application's ServiceAccount can `get` only `api-key-v2`, and is denied access to every other Secret in the namespace.

---

## 📋 Tasks

All resources must be created in the **`finance`** namespace.

**1.** Create a Secret named **`api-key-v2`**
- Type: `Opaque`
- Content can be anything, e.g. `key=supersecret`

**2.** Create a ServiceAccount named **`specific-secret-reader-sa`**

**3.** Create a Role named **`single-secret-getter-role`** with:
- API group: `""` (core)
- Resource: `secrets`
- Verb: `get`
- Restricted to: `resourceNames: ["api-key-v2"]`

**4.** Create a RoleBinding named **`single-secret-getter-binding`** that binds:
- Role `single-secret-getter-role` → ServiceAccount `specific-secret-reader-sa`

---

## ✅ Expected Result

```bash
# Allowed ✔
kubectl auth can-i get secrets/api-key-v2 \
  --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance
# → yes

# Denied ✘
kubectl auth can-i get secrets/some-other-secret \
  --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance
# → no

# Denied ✘ (cannot list all secrets)
kubectl auth can-i get secrets \
  --as=system:serviceaccount:finance:specific-secret-reader-sa -n finance
# → no
```

---

<details>
<summary>💡 Solution (try it yourself first!)</summary>

**Using kubectl commands:**

```bash
# 1. Secret
kubectl create secret generic api-key-v2 \
  --from-literal=key=supersecret -n finance

# 2. ServiceAccount
kubectl create sa specific-secret-reader-sa -n finance

# 3. Role with resourceNames restriction
kubectl create role single-secret-getter-role \
  --verb=get \
  --resource=secrets \
  --resource-name=api-key-v2 \
  -n finance

# 4. RoleBinding
kubectl create rolebinding single-secret-getter-binding \
  --role=single-secret-getter-role \
  --serviceaccount=finance:specific-secret-reader-sa \
  -n finance
```

**Using YAML:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-key-v2
  namespace: finance
type: Opaque
stringData:
  key: supersecret
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

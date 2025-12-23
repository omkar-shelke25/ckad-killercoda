### 🧩 **CKAD: Fix RBAC Access for Deployment Using a Predefined Role**


### 📚 **Official Kubernetes Documentation**: 

- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
- [RoleBinding and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [ServiceAccounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)


A Deployment named **`pod-explorer`** in the **`qa-tools`** namespace is failing with the following error:

```
Error from server (Forbidden): pods is forbidden:
User "system:serviceaccount:qa-tools:sa-explorer" cannot list resource "pods" in API group "" in the namespace "qa-tools"
```

The security team has already created several predefined Roles within the namespace.

**Tasks:**

1. From the existing Roles in the `qa-tools` namespace, **choose the Role that grants read-only access to Pods**.
2. Bind the selected Role to the ServiceAccount `sa-explorer` using a RoleBinding named `explorer-rolebinding`.
3. Verify that the Deployment can now successfully list Pods in the `qa-tools` namespace.


---

## ✅ Solution Steps

<details>
<summary>💡 Click here if you need help</summary>

### Step-by-Step Solution:

**1. List all Roles:**
```bash
kubectl get roles -n qa-tools
```

Expected output:
```
NAME                AGE
config-reader       12m
secret-reader       25m
pod-reader          25m  
deployment-viewer   25d
```

**2. Inspect each Role to find the correct one:**

```bash
# Check config-reader
kubectl describe role config-reader -n qa-tools

# Check secret-reader
kubectl describe role secret-reader -n qa-tools

# Check pod-reader (this is the correct one!)
kubectl describe role pod-reader -n qa-tools

# Check deployment-viewer
kubectl describe role deployment-viewer -n qa-tools
```

The **`pod-reader`** Role has the correct permissions:
- Resources: `pods`, `pods/log`
- Verbs: `get`, `list`, `watch`

**3. Create the RoleBinding:**

```bash
kubectl create rolebinding explorer-rolebinding \
  --role=pod-reader \
  --serviceaccount=qa-tools:sa-explorer \
  -n qa-tools
```

**4. Verify the RoleBinding was created:**

```bash
kubectl get rolebinding explorer-rolebinding -n qa-tools
kubectl describe rolebinding explorer-rolebinding -n qa-tools
```

**5. Test permissions:**

```bash
# Should now return "yes"
kubectl auth can-i list pods --as=system:serviceaccount:qa-tools:sa-explorer -n qa-tools
```

**6. Check deployment logs:**

```bash
kubectl logs deployment/pod-explorer -n qa-tools --tail=20 -f
```

You should see success messages! 🎉

</details>

---

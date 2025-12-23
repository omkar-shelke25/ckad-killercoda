# CKAD: Investigate & Fix the RBAC Role

## 📚 **Official Kubernetes Documentation**: 

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
- [RoleBinding and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [ServiceAccounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

A developer using ServiceAccount **`dev-user-1`** in **`project-alpha`** cannot list ConfigMaps, even though there is a Role and RoleBinding in place.



## Task

1. Inspect the Role **`config-reader`** and the RoleBinding **`dev-user-1-binding`** in the `project-alpha` namespace.
2. Identify the misconfiguration preventing listing of ConfigMaps.
3. **Fix the live Role object** (do not delete/recreate).
4. Verify that `dev-user-1` can list ConfigMaps in `project-alpha`.

---

<summary>Solution (expand to view)</summary>


1) Confirm the problem

```bash
kubectl auth can-i list configmaps \
  --as=system:serviceaccount:project-alpha:dev-user-1 -n project-alpha
```

You should see below :: 

2) Inspect Role and RoleBinding

```bash
kubectl -n project-alpha get role config-reader -o yaml
kubectl -n project-alpha get rolebinding dev-user-1-binding -o yaml
```

Notice the Role uses resources: ["configmap"] (singular). It must be configmaps (plural).
```bash
kubectl api-resources | grep -i configmap  # It must be configmaps (plural).
```

3a) Fix in-place using kubectl edit
```bash
kubectl -n project-alpha edit role config-reader

# Change:
#   resources: ["configmap"]
# To:
#   resources: ["configmaps"]
# Save & exit
```

3b) (Alternative) Patch in-place

```bash
kubectl -n project-alpha patch role config-reader \
  --type='json' \
  -p='[{"op":"replace","path":"/rules/0/resources/0","value":"configmaps"}]'
```

4) Verify

```bash
kubectl auth can-i list configmaps \
  --as=system:serviceaccount:project-alpha:dev-user-1 -n project-alpha
```


</details>

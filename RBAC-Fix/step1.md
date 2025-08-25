# Investigate & Fix the RBAC Role

A developer using ServiceAccount **`dev-user-1`** in **`project-alpha`** cannot list ConfigMaps, even though there is a Role and RoleBinding in place.

## Task

1. Inspect the Role **`config-reader`** and the RoleBinding **`dev-user-1-binding`** in the `project-alpha` namespace.
2. Identify the misconfiguration preventing listing of ConfigMaps.
3. **Fix the live Role object** (do not delete/recreate).
4. Verify that `dev-user-1` can list ConfigMaps in `project-alpha`.

---

<details>
<summary>short notes on RBAC `resources`</summary>

# 📒 RBAC Resources – Short Notes

### 🔑 Rules

* Always use **plural** names in `resources` (e.g., `configmaps`, not `configmap`).
* Names must match **API resource list** → check with:

  ```bash
  kubectl api-resources
  ```
* ❌ Singular / Short names (e.g., `cm`, `svc`) are invalid.
* ✅ Always lowercase.

---

### ✅ Common Plural Names

* Pod → `pods`
* Service → `services`
* ConfigMap → `configmaps`

</details>


<details> 
<summary>Solution (expand to view)</summary>


1) Confirm the problem

```bash
kubectl auth can-i list configmaps \
  --as=system:serviceaccount:project-alpha:dev-user-1 -n project-alpha
```

You should see no.

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

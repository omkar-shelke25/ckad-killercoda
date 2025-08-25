# 🧩 Task — Allow Only Pod Log Access via Cross-namespace Binding (Weight: 6)

You need a ServiceAccount that can **only view Pod logs** in `app-prod`. It must not be able to read Pod specs, list Pods, or do anything else.

## 🎯 Objective
- Use the existing namespace **`default`** for the ServiceAccount.
- Create **ServiceAccount** `log-scraper-sa` in **`default`**.
- Create **Role** `log-reader-role` in **`app-prod`** that grants **only**:
  - `verbs: ["get"]`
  - `resources: ["pods/log"]` (subresource)
  - `apiGroups: [""]` (core)
- Create **RoleBinding** `log-scraper-binding` in **`app-prod`** that binds **Role → ServiceAccount `default/log-scraper-sa`**.


---

## 💡 Hints (expand)
<details>
<summary>Imperative commands</summary>

```bash
kubectl create sa -n default log-scraper-sa

kubectl create role log-reader-role \
  -n app-prod \
  --verb=get \
  --resource=pods/log

kubectl create rolebinding log-scraper-binding \
  -n app-prod \
  --role=log-reader-role \
  --serviceaccount default:log-scraper-sa
```

</details>

<details> <summary>Impersonation test</summary>
```bash 
# positive (in app-prod, subresource=log)
kubectl auth can-i -n app-prod get pods --subresource=log \
  --as=system:serviceaccount:default:log-scraper-sa

# negatives
kubectl auth can-i -n app-prod get pods \
  --as=system:serviceaccount:default:log-scraper-sa

kubectl auth can-i -n app-prod list pods --subresource=log \
  --as=system:serviceaccount:default:log-scraper-sa

kubectl auth can-i -n default get pods --subresource=log \
  --as=system:serviceaccount:default:log-scraper-sa
```
<details> <summary>Minimal YAML (optional)</summary>

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: log-scraper-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: log-reader-role
  namespace: app-prod
rules:
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: log-scraper-binding
  namespace: app-prod
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: log-reader-role
subjects:
- kind: ServiceAccount
  name: log-scraper-sa
  namespace: default
```
</details>


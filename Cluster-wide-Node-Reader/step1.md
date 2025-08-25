# 🧩 ClusterRole & ClusterRoleBinding for Node Read + Attach SA (Weight: 6)

A monitoring UI is running in `monitoring` as `Deployment: node-inspector-ui`.  
It must use a **dedicated ServiceAccount** with **cluster-wide read-only access to Node resources**.

## 🎯 Objective
- Create a **ServiceAccount** named `node-inspector-sa` in `monitoring`.
- Create a **ClusterRole** named `node-reader-crole` with read-only access to **nodes**.
- Create a **ClusterRoleBinding** named `node-inspector-crbinding` that grants the ClusterRole to the ServiceAccount.
- **Assign `node-inspector-sa` to the `node-inspector-ui` Deployment** (`spec.template.spec.serviceAccountName`).
- Verify effective permissions via impersonation.

## 📋 Requirements
- Namespace: `monitoring` *(already exists)*
- ServiceAccount: `node-inspector-sa` (in `monitoring`)
- ClusterRole: `node-reader-crole`
  - `apiGroups: [""]`
  - `resources: ["nodes"]`
  - `verbs: ["get","list"]`
- ClusterRoleBinding: `node-inspector-crbinding`
  - `roleRef` → **ClusterRole** `node-reader-crole`
  - `subjects[0]` → **ServiceAccount** `node-inspector-sa` in namespace `monitoring`
- Update `Deployment/node-inspector-ui` to run with `serviceAccountName: node-inspector-sa`

---

## 💡 Hints (expand)
<details>
<summary>Imperative commands</summary>

```bash
kubectl create sa node-inspector-sa -n monitoring

kubectl create clusterrole node-reader-crole \
  --verb=get --verb=list \
  --resource=nodes

kubectl create clusterrolebinding node-inspector-crbinding \
  --clusterrole node-reader-crole \
  --serviceaccount monitoring:node-inspector-sa

# Attach SA to Deployment (will trigger a rollout)
kubectl -n monitoring patch deployment node-inspector-ui \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"node-inspector-sa"}}}}'
```
</details>

<details> <summary>Impersonation”</summary>

```bash
kubectl auth can-i get nodes \
  --as=system:serviceaccount:monitoring:node-inspector-sa

kubectl auth can-i list nodes \
  --as=system:serviceaccount:monitoring:node-inspector-sa

kubectl auth can-i delete nodes \
  --as=system:serviceaccount:monitoring:node-inspector-sa
```
</details>


<details> <summary>YAML bundle (optional)</summary>

```bash
apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-inspector-sa
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader-crole
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-inspector-crbinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: node-reader-crole
subjects:
- kind: ServiceAccount
  name: node-inspector-sa
  namespace: monitoring
```

</details>

# CKAD: Update Deployment In-Place

A financial services company runs a critical application as a Kubernetes Deployment named **gamma-app** in the **prod** namespace. The DevOps team needs to update the container configuration for compliance and standardization purposes.

The Deployment currently uses the default **nginx** container with image `nginx:latest`.

### Your Tasks

1. Update the Deployment so that the container uses the image `nginx:stable`.
2. Change the container name from `nginx` to `gamma-nginx`.
3. Ensure that the **Deployment object is not deleted or recreated** (the Deployment UID must remain the same).

Confirm the changes are applied successfully.

---

## 💡 Tips
- The Deployment should be updated in-place without deleting and recreating it
- You can use `kubectl edit`, `kubectl set`, or `kubectl patch` commands
- Verify the Deployment UID hasn't changed after your updates
- Check that pods are running with the new configuration

---

# Try it yourself first!

<details><summary>✅ Solution For Your Reference</summary>

```bash
# Check current state
kubectl -n prod get deploy gamma-app -o wide
kubectl -n prod get deploy gamma-app -o jsonpath='{.metadata.uid}'

# Method 1: Using kubectl set image and kubectl edit
# First, update the image
kubectl -n prod set image deploy/gamma-app nginx=nginx:stable

# Then, edit to change container name (change 'name: nginx' to 'name: gamma-nginx')
kubectl -n prod edit deploy gamma-app

# Method 2: Using kubectl patch (single command)
kubectl -n prod patch deploy gamma-app --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/name", "value": "gamma-nginx"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "nginx:stable"}
]'

# Method 3: Using kubectl edit directly
kubectl -n prod edit deploy gamma-app
# Change:
#   - name: nginx           -> name: gamma-nginx
#   - image: nginx:latest   -> image: nginx:stable

# Verify the changes
kubectl -n prod get deploy gamma-app -o jsonpath='{.spec.template.spec.containers[0].name}'
kubectl -n prod get deploy gamma-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Verify UID hasn't changed
kubectl -n prod get deploy gamma-app -o jsonpath='{.metadata.uid}'

# Wait for rollout to complete
kubectl -n prod rollout status deploy/gamma-app
```

</details>

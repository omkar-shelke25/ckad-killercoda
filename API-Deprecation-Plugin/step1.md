# CKAD: API Deprecation and Deployment

## 📚 **Official Kubernetes Documentation**:

- [Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [API Versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning)
- [kubectl-convert Plugin](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-convert-plugin)
- [Install kubectl on Linux](https://https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [kubectl Plugins Overview](https://kubernetes.io/docs/tasks/exte)


You are working in a Kubernetes cluster (v1.33). A manifest file contains **deprecated API versions** that are no longer supported.

### Scenario
The development team at your company has provided a manifest file at `/ancient-tiger/app.yaml` that was created for Kubernetes v1.28. However, your cluster is running v1.33, and some API versions have been deprecated and removed.

### Your Tasks

1. **Inspect the manifest file** at `/ancient-tiger/app.yaml` to identify deprecated API versions.

2. **Fix all API deprecation issues** in the manifest so that it becomes compatible with Kubernetes v1.33.
   - **Download and install kubectl-convert plugin** (recommended approach) rather than manually editing
   - Save the updated file in the same location with the same name
3. **Deploy the application** using the updated manifest file into the **viper** namespace.
4. **Verify** that the application Pods are successfully running in the **viper** namespace.

---

## Installing kubectl Convert (Linux)

Follow the official Kubernetes documentation for installing `kubectl convert` on Linux.  
Here’s the relevant page:  
[Install kubectl on Linux (official docs)](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)  

> In the exam, you may face tasks that require fixing manifests with **deprecated API versions**.The `kubectl-convert` plugin is very useful for this, but **it is not pre-installed in the exam environment**.You must install it yourself during the exam if needed.

---

# Try it yourself first!

<details><summary>✅ Solution For Your Reference</summary>

```bash
# Step 1: Inspect the current manifest
cat /ancient-tiger/app.yaml

# Check available API versions
kubectl api-versions | grep apps

# Step 2: Use kubectl-convert to automatically fix deprecated APIs
# apps/v1beta1 is deprecated, convert to apps/v1
# kubectl-convert automatically adds required fields like selector
kubectl-convert -f /ancient-tiger/app.yaml --output-version apps/v1

# Step 3: Create the viper namespace
kubectl create namespace viper

# Step 4: Convert and save the manifest with namespace change
kubectl-convert -f /ancient-tiger/app.yaml --output-version apps/v1 | \
  sed 's/namespace: anaconda/namespace: viper/g' > /tmp/converted.yaml
mv /tmp/converted.yaml /ancient-tiger/app.yaml

# Verify the converted manifest
cat /ancient-tiger/app.yaml

# Step 5: Apply the manifest
kubectl apply -f /ancient-tiger/app.yaml

# Step 6: Verify the deployment
kubectl get pods -n viper
kubectl get deployment -n viper
kubectl rollout status deployment/web-app -n viper

```

**Key points:**
- `apps/v1beta1` was deprecated and removed in Kubernetes v1.16+
- `apps/v1` requires a `selector` field in Deployment spec
- The namespace was changed from "anaconda" to "viper" as per requirements

</details>

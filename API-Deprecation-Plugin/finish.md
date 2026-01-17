# 🎉 Completed

You successfully:
- **Identified** deprecated API versions in the manifest (`apps/v1beta1`)
- **Fixed** the API deprecation by updating to `apps/v1`
- **Added** the required `selector` field for apps/v1 Deployment
- **Deployed** the application to the **viper** namespace
- **Verified** that all 3 pods are running successfully


## 💬 Have a doubt?

🔗 **Discord Link:**
[https://killercoda.com/discord](https://killercoda.com/discord)

## Key Takeaways

### API Deprecations
- Kubernetes regularly deprecates old API versions as the platform evolves
- `apps/v1beta1` and `apps/v1beta2` were deprecated and removed in v1.16
- Always use stable API versions like `apps/v1` for Deployments, StatefulSets, and DaemonSets

### Required Fields
- The `apps/v1` API version requires a `selector` field in Deployment specs
- The selector must match the pod template labels
- This requirement improves clarity and prevents misconfigurations

### Tools
- **kubectl-convert**: Automatically converts manifests to newer API versions
- **kubectl api-versions**: Lists all available API versions in your cluster
- **kubectl explain**: Shows documentation and required fields for resources

### Best Practices
1. Always check API version compatibility when upgrading clusters
2. Use `kubectl-convert` to migrate manifests automatically
3. Test manifests in a non-production environment first
4. Keep manifests updated with current stable API versions

## CKAD Exam Tips
- Know how to identify and fix deprecated APIs quickly
- Be familiar with `kubectl-convert` and `kubectl explain`
- Remember that apps/v1 requires selectors for Deployments
- Practice converting common resources (Deployment, DaemonSet, StatefulSet, Ingress)

Great job! This skill is essential for maintaining Kubernetes applications across cluster upgrades.

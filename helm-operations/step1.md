# Helm Operations

**Namespace:** `sercury` (unless stated otherwise)

## **Question (Weightage: 4)**

1. **Delete** the release **`internal-issue-report-apiv1`** in `sercury`.
2. **Upgrade** the release **`internal-issue-report-apiv2`** in `sercury` from bitnami/nginx **18.2.6** to **exact chart version `21.1.23`**.
3. **Install** a new release **`internal-issue-report-apache`** in `sercury` from chart **`bitnami/apache`** with the Deployment replica count set to **2** via Helm **values** (do not edit manifests).
4. **Find** the release named **`vulnerabilities`** and **uninstall** it.

---

## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>
  
```bash
# Inspect current releases
helm ls -n sercury -a
helm ls -n venus -a
helm ls -A -a

# Delete
helm uninstall internal-issue-report-apiv1 -n sercury

# Find nginx chart versions
helm search repo bitnami/nginx --versions

# Upgrade to an exact version
helm upgrade internal-issue-report-apiv2 bitnami/nginx -n sercury --version 21.1.23

# Install apache with replicas via values
helm show values bitnami/apache | grep -i replica
helm install internal-issue-report-apache bitnami/apache -n sercury --set replicaCount=2

# Remove cross-namespace release
helm uninstall vulnerabilities -n venus

```
</details>

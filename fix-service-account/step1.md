# CKAD: Fix Payment API ServiceAccount


In the namespace `payment`, the Deployment **`payment-api`** is running with pods that use the **default ServiceAccount**.  

These pods must instead use the dedicated ServiceAccount `payment-sa`, which already has the correct RBAC permissions to access secrets.

---

### Task
Update the Deployment `payment-api` in the `payment` namespace to use the ServiceAccount `payment-sa`.


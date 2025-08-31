# CKAD: Fix Payment API ServiceAccount

A startup is running their **payment-api** deployment in the `payment` namespace.  
Currently, the pods for this deployment are using the **default ServiceAccount**, which does not have permissions to access sensitive payment secrets.

The security team has already created:
- A ServiceAccount named **payment-sa** in `payment`
- A Role named **secret-accessor** that can **get, list, watch secrets**
- A RoleBinding named **payment-secret-binding** that binds the Role to the ServiceAccount

Your task is to fix the Deployment so its pods run as the **payment-sa** ServiceAccount.

Click **Start Scenario** to begin.

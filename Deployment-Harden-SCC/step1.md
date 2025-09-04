# CKAD: Harden a Deployment (non-root, no-priv-escalation, NET_BIND_SERVICE)

A Deployment named **`busybox`** exists in the **`net-acm`** namespace. The security team has flagged this workload during their audit and requires immediate remediation.

### Requirements
Update the **`busybox`** Deployment so that its container:
- **Runs as non-root**
- Has **`allowPrivilegeEscalation: false`**
- Adds the Linux capability **`NET_BIND_SERVICE`**

> Notes
> - Namespace, Deployment, and a dummy Service are **already created**.
> - You may edit and apply the Deployment spec (e.g., `kubectl edit` or `kubectl apply -f`).
> - Assume the application will continue to operate with these constraints.

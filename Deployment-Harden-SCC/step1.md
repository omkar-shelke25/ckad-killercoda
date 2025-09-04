Solve this task on the provided cluster instance.

A Deployment named **`busybox`** exists in the **`net-acm`** namespace. The security team has flagged this workload during their audit and requires immediate remediation.

### Requirements
Update the **`busybox`** Deployment so that its container:
- **Runs as non-root**
- Has **`allowPrivilegeEscalation: false`**
- Has Linux capability **`NET_BIND_SERVICE`** added (no extra capabilities beyond that)

After making these changes, your team lead wants to verify the implementation.  
Create a shell script at **`/net-acm/id.sh`** that prints the **user ID** the Pod is running as (for the compliance report).

> Notes
> - The application team confirmed the busybox container continues to function with these constraints.
> - The namespace, Deployment, and a dummy Service are pre-created.
> - You may edit the existing Deployment spec; replacing it is fine as long as the name/namespace stay the same.

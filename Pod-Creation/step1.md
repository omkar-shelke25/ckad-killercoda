# Pod Creation with Status Command Requirement

Work in the **default** namespace.

## Task

- Create a Pod named **pod1** that runs a single container:
  - Container name: **pod1-container**
  - Image: **httpd:2.4.41-alpine**

- Provide a shell script at: **/opt/course/2/pod1-status-command.sh**

The script must use **kubectl** to print the **status phase** of Pod `pod1` in the `default` namespace  
(e.g., `Running`, `Pending`, `Succeeded`, etc.).



## Solution

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>


```yaml
apiVersion: v1
kind: Pod
metadata:
name: pod1
namespace: default
spec:
containers:
- name: pod1-container
  image: httpd:2.4.41-alpine
```

```bash
echo "kubectl get pod pod1 -n default -o jsonpath='{.status.phase}'" > /opt/course/2/pod1-status-command.sh
```
</details>

## 🧩 **Pod Creation with Status Command Requirement**

**Namespace:** `default`

### **Task Description**

1. Create a Pod named **`pod1`** in the **default** namespace.

   * The Pod should contain **one container** with the following details:

     * **Container name:** `pod1-container`
     * **Image:** `httpd:2.4.41-alpine`

2. Create a shell script at the path:
   **`/opt/course/2/pod1-status-command.sh`**

   The script must use `kubectl` to print the **status phase** of the Pod `pod1`
   (for example: `Running`, `Pending`, `Succeeded`, etc.).

3. You must **execute the script at least once** before submitting your work
   (i.e., run `/opt/course/2/pod1-status-command.sh` before clicking “Check”).

---

### ✅ **Example Expected Script Output**

If the Pod is running successfully, executing the script should print:

```
Running
```


## Solution

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

```bash
k run po pod1 --image httpd:2.4.41-alpine --dry-run=client -oyaml > 1.yaml
```

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
chmod +x /opt/course/2/pod1-status-command.sh
/opt/course/2/pod1-status-command.sh
```
</details>

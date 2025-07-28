# 🛠️ Step 1: Modify app-pod Labels

## 🎯 Task
The existing NetworkPolicy `restrict-app-pod` in the `ckad-netpol` namespace allows ingress and egress traffic for pods with the label `role: allowed-app`. Currently, `app-pod` does not have this label, so it cannot communicate as required. Your task is to modify `app-pod` to comply with the NetworkPolicy by adding the correct label.

### 📋 Instructions
1. **🔍 Inspect the NetworkPolicy**:
   Check the NetworkPolicy to understand its restrictions:
   ```bash
   kubectl -n ckad-netpol get networkpolicy
   kubectl -n ckad-netpol describe networkpolicy restrict-app-pod
   ```
   Look for the `podSelector` and labels used in the ingress and egress rules.

2. **🔎 Check app-pod’s Current Labels**:
   View `app-pod`’s labels to confirm it’s missing the required label:
   ```bash
   kubectl -n ckad-netpol get pod app-pod --show-labels
   ```

3. **✏️ Modify app-pod’s Labels**:
   Add the label `role=allowed-app` to `app-pod`. You can edit the pod directly:
   ```bash
   kubectl -n ckad-netpol edit pod app-pod
   ```
   In the editor, under `metadata.labels`, add:
   ```yaml
   role: allowed-app
   ```
   Save and exit the editor.

   Alternatively, use the `kubectl label` command:
   ```bash
   kubectl -n ckad-netpol label pod app-pod role=allowed-app
   ```

4. **✅ Verify the Label**:
   Confirm the label was added:
   ```bash
   kubectl -n ckad-netpol get pod app-pod --show-labels
   ```

5. **🔌 Verify Connectivity**:
   Test ingress to `app-pod` from `frontend-pod`:
   ```bash
   kubectl exec -n ckad-netpol frontend-pod -- curl http://app-pod.ckad-netpol.svc.cluster.local
   ```
   Test egress from `app-pod` to `backend-pod` (port 6379):
   ```bash
   kubectl exec -n ckad-netpol app-pod -- curl http://backend-pod.ckad-netpol.svc.cluster.local:6379
   ```

6. **🛡️ Verify Pod Status**:
   Ensure `app-pod` is still running:
   ```bash
   kubectl -n ckad-netpol get pod app-pod
   ```

7. **🧪 Run Verification**:
   Run the verification script to check your work:
   ```bash
   /bin/verify.sh
   ```
   - If it passes, you’ll see a success message (✅).
   - If it fails, you’ll see an error message (❌) and can view the solution below or retry.

### ❓ Solution (View Only If Verification Fails)
If the verification script fails, check the solution below:

<details>
<summary>Click to reveal the solution</summary>

To make `app-pod` comply with the NetworkPolicy:
1. Add the `role: allowed-app` label to `app-pod`:
   ```bash
   kubectl -n ckad-netpol label pod app-pod role=allowed-app
   ```
2. Verify the label:
   ```bash
   kubectl -n ckad-netpol get pod app-pod --show-labels
   ```
3. Test connectivity:
   ```bash
   kubectl exec -n ckad-netpol frontend-pod -- curl http://app-pod.ckad-netpol.svc.cluster.local
   kubectl exec -n ckad-netpol app-pod -- curl http://backend-pod.ckad-netpol.svc.cluster.local:6379
   ```
4. Ensure the pod is running:
   ```bash
   kubectl -n ckad-netpol get pod app-pod
   ```

The NetworkPolicy selects pods with `role: allowed-app`, so this label ensures `app-pod` can send and receive traffic as required.
</details>

### 📝 Notes
- The NetworkPolicy selects pods with `role: allowed-app` for ingress and egress traffic.
- Only modify `app-pod`’s labels; do not change the NetworkPolicy or other resources.
- If connectivity tests fail, ensure the pod is running and the label is correct.

When you’ve passed the verification, click **Next** to finish! 🚀
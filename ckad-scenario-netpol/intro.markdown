# 🛡️ CKAD: Network Policy Restriction

## 📖 Scenario Overview
In this scenario, you will configure a pod named `app-pod` in the `ckad-netpol` namespace to comply with an existing NetworkPolicy. The NetworkPolicy restricts ingress traffic to `app-pod` to only come from pods labeled `role=frontend` or `role=backend` in the same namespace. Similarly, it restricts egress traffic from `app-pod` to only those pods. You cannot modify the NetworkPolicy; instead, you must adjust `app-pod` to comply with these restrictions.

## 🎯 Task
- **Objective**: Modify `app-pod` to allow ingress traffic from and egress traffic to pods labeled `role=frontend` and `role=backend` in the `ckad-netpol` namespace.
- **Constraints**: You cannot create, update, or delete any NetworkPolicy resources. Only modify `app-pod`’s configuration (e.g., labels).
- **Verification**: Ensure `app-pod` is running after changes and test connectivity using:
  ```bash
  kubectl exec -n ckad-netpol frontend-pod -- curl http://app-pod.ckad-netpol.svc.cluster.local
  ```

## 🛠️ Setup
The environment is preconfigured with:
- **Namespace**: `ckad-netpol`
- **Pods**: `app-pod`, `frontend-pod`, `backend-pod`
- **NetworkPolicy**: `restrict-app-pod` (defines the restrictions)

Click **Next** to start the task! 🚀
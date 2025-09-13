# CKAD: Complex NetworkPolicy Pod Communication Challenge

In namespace **`netpol-challenge`**, there are 3 pods and 3 NetworkPolicies:

**Pods:**
- `frontend-pod` (nginx:1.20-alpine)
- `backend-pod` (nginx:1.20-alpine) 
- `target-pod` (nginx:1.20-alpine)

**NetworkPolicies:** (DO NOT MODIFY THESE!)
- `target-ingress-policy`
- `target-egress-policy` 
- `target-default-deny`

## Your Task

You must configure the pod labels so that **`target-pod`** can:
- ✅ **Receive** inbound traffic from ONLY `frontend-pod` and `backend-pod`
- ✅ **Send** outbound traffic to ONLY `frontend-pod` and `backend-pod`
- ❌ **Block** all other traffic (default deny)

## Restrictions
- 🚫 You **CANNOT** create, delete, or modify any NetworkPolicy
- ✅ You can **ONLY** modify pod labels
- ✅ You must analyze the existing NetworkPolicies to understand the required labels

## Try it yourself first!

<details><summary>💡 Hint (expand if needed)</summary>

Look at the NetworkPolicy selectors:
- What labels do the policies expect on the target pod?
- What labels do the policies expect on the frontend and backend pods?
- Remember: NetworkPolicies use `podSelector` and `matchLabels` to identify pods.

</details>

<details><summary>✅ Solution (expand to view)</summary>

### ✅ Step 1: Analyze the NetworkPolicies

First, examine the existing NetworkPolicies to understand their label requirements:

```bash
# Check all NetworkPolicies
kubectl -n netpol-challenge describe netpol target-ingress-policy
kubectl -n netpol-challenge describe netpol target-egress-policy
kubectl -n netpol-challenge describe netpol target-default-deny
```

From the policies, we can see:
- All policies target pods with label `role=target-app`
- Ingress/Egress policies allow communication with pods labeled `app=frontend` and `app=backend`

---

### ✅ Step 2: Apply the correct labels

Since the Pods were created with the wrong labels (`wrong=label`), update them:

```bash
# Label the target pod (this pod will be isolated by the NetworkPolicies)
kubectl -n netpol-challenge label pod target-pod role=target-app --overwrite

# Label the frontend pod (this pod can communicate with target-pod)
kubectl -n netpol-challenge label pod frontend-pod app=frontend --overwrite

# Label the backend pod (this pod can communicate with target-pod)
kubectl -n netpol-challenge label pod backend-pod app=backend --overwrite
```

---

### ✅ Step 3: Verify the labels

```bash
kubectl -n netpol-challenge get pods --show-labels
```

You should see:

```
NAME           READY   STATUS    RESTARTS   AGE   LABELS
frontend-pod   1/1     Running   0          5m    app=frontend,type=frontend
backend-pod    1/1     Running   0          5m    app=backend,type=backend
target-pod     1/1     Running   0          5m    role=target-app,type=target
```

---

### ✅ Step 4: Inspect the NetworkPolicies (verification)

Check that the policies now match the pod labels:

```bash
kubectl -n netpol-challenge describe netpol target-ingress-policy
kubectl -n netpol-challenge describe netpol target-egress-policy
kubectl -n netpol-challenge describe netpol target-default-deny
```

You should see:

* **PodSelector: role=target-app** (applies to target-pod)
* **Ingress from:** Pods with labels `app=frontend` and `app=backend`
* **Egress to:** Pods with labels `app=frontend` and `app=backend`
* **PolicyTypes:** Ingress, Egress

---

### ✅ Step 5: Test the network policies (optional)

```bash
# Test that target-pod can be reached from frontend-pod
kubectl -n netpol-challenge exec frontend-pod -- wget -qO- --timeout=2 target-pod

# Test that target-pod can be reached from backend-pod  
kubectl -n netpol-challenge exec backend-pod -- wget -qO- --timeout=2 target-pod
```

---

✅ **Final result:**

* Pod `target-pod` is isolated and can only send/receive traffic to/from Pods `frontend-pod` and `backend-pod`, because the labels now align with the pre-existing NetworkPolicies.

</details>

[Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

[Traefik Kubernetes Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)

# **CKAD: Validate and Fix Ingress Paths**

A Deployment setup for the **Food Delivery App** is already running in the namespace **`food-app`**.

A manifest file located at **`/app/food-deliver.yaml`** already defines an **Ingress** resource with two paths — **`/menu`** and **`/order-details`**.

---

## **Your Task**

1. **Check** the existing Ingress configuration inside `/app/food-deliver.yaml` and make sure the existing paths are correctly configured according to their respective services:

   * `/menu`
   * `/order-details`

2. **Add** the following missing paths (if not already present) and route them to the specified backends:

   * `/payment` → service **`payment-service`**, port **8003**
   * `/track-order` → service **`tracking-service`**, port **8004**

3. **Update** the Ingress to include the following top-level settings:

   * `ingressClassName: traefik`
   * `host: fast.delivery.io`

4. **Apply** the manifest after making the changes by editing **only** `/app/food-deliver.yaml` and running:

   ```bash
   kubectl apply -f /app/food-deliver.yaml
   ```

---

#### ✅ **Valid paths (should return HTTP 200 + JSON)**

```bash
curl fast.delivery.io:32080/menu | jq
curl fast.delivery.io:32080/order-details | jq
curl fast.delivery.io:32080/payment | jq
curl fast.delivery.io:32080/track-order | jq
```

---

## 💡 Complete Solution
<details><summary>✅ Solution (Click to expand)</summary>

### **Step 1: Fix Payment Service Selector**

**Reason:**
The `payment-service` had no endpoints because its selector was incorrect (`app: payments`) while pods were labeled `app: payment-service`.
Kubernetes services find pods by matching `selector` labels — mismatch = no traffic routing.

**Fix:**
Update the selector so it matches pod labels.

```bash
kubectl -n food-app patch service payment-service -p '{"spec":{"selector":{"app":"payment-service"}}}'
```

✅ After patching, verify endpoints are populated:

```bash
kubectl -n food-app get endpoints payment-service
```

---

### **Step 2: Fix and Complete Ingress Configuration**

**Reason:**
The existing `/app/food-deliver.yaml` ingress:

* had **wrong port (8005)** for `/order-details`
* was **missing** `/payment` and `/track-order` paths
* lacked required **`ingressClassName`** and **`host`** fields
  These are required for correct routing via Traefik and for external access.

---

**Fix:** Edit the manifest:

```bash
vi /app/food-deliver.yaml
```

Replace contents with:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: food-app-ingress
  namespace: food-app
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  ingressClassName: traefik
  rules:
  - host: fast.delivery.io
    http:
      paths:
      - path: /menu
        pathType: Prefix
        backend:
          service:
            name: menu-service
            port:
              number: 8001
      - path: /order-details
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 8002
      - path: /payment
        pathType: Prefix
        backend:
          service:
            name: payment-service
            port:
              number: 8003
      - path: /track-order
        pathType: Prefix
        backend:
          service:
            name: tracking-service
            port:
              number: 8004
```

Apply:

```bash
kubectl apply -f /app/food-deliver.yaml
```

✅ This ensures:

* correct ingress class (`traefik`)
* correct domain (`fast.delivery.io`)
* all four paths routed to correct backend ports

---

### **Step 3: Verify Configuration**

**Check Ingress and Endpoints**

```bash
kubectl -n food-app get ingress food-app-ingress
kubectl -n food-app describe ingress food-app-ingress
kubectl -n food-app get endpoints payment-service
```

Expected:

* `Host: fast.delivery.io`
* `Class: traefik`
* Paths: `/menu`, `/order-details`, `/payment`, `/track-order`
* Each service has active endpoints.

---

### **Step 4: Test All Endpoints**

**Reason:**
To confirm ingress routes traffic correctly through NodePort `32080`.

**Run:**

```bash
curl http://fast.delivery.io:32080/menu | jq
curl http://fast.delivery.io:32080/order-details | jq
curl http://fast.delivery.io:32080/payment | jq
curl http://fast.delivery.io:32080/track-order | jq
```

✅ **Expected Results:**
Each endpoint returns valid JSON and respective service messages:

* `/menu` → menu details
* `/order-details` → order info
* `/payment` → payment status
* `/track-order` → tracking info

---

**💡 Summary**

| Change                                                       | Reason                           |
| ------------------------------------------------------------ | -------------------------------- |
| Fixed `payment-service` selector                             | to connect Service → Pods        |
| Corrected `order-details` port from 8005 → 8002              | match real service port          |
| Added `/payment` & `/track-order` paths                      | missing from ingress             |
| Added `ingressClassName: traefik` & `host: fast.delivery.io` | required for routing             |
| Verified via `curl`                                          | ensure all paths return HTTP 200 |

✅ All services reachable → Ingress and Services correctly configured.

</details>

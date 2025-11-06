# **CKAD: Validate and Fix Ingress Paths**


A Deployment setup for the **Food Delivery App** is already running in the namespace **`food-app`**.

A manifest file located at **`/app/food-deliver.yaml`** already defines an **Ingress** resource with two paths — **`/menu`** and **`/order-details`**.

---

### **Your Task**

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

## 💡 Complete Solution
<details><summary>✅ Solution (Click to expand)</summary>
<details><summary>🔍 Part 1: Fix Payment Service Selector (Click to expand)</summary>

### Step 1: Identify the Issue

Check service endpoints:
```bash
kubectl -n food-app get endpoints payment-service
```

You'll notice it has no endpoints.

Check pod labels:
```bash
kubectl -n food-app get pods -l app=payment-service --show-labels
```

Check service selector:
```bash
kubectl -n food-app get service payment-service -o yaml | grep -A2 selector
```

**Problem**: Service selector is `app: payments` but pods have label `app: payment-service`.

### Step 2: Fix the Selector

Edit the service:
```bash
kubectl -n food-app edit service payment-service
```

Change:
```yaml
selector:
  app: payments
```

To:
```yaml
selector:
  app: payment-service
```

Save and exit.

### Step 3: Verify the Fix

```bash
# Check endpoints now
kubectl -n food-app get endpoints payment-service

# Should show 2 pod IPs (2 replicas)
```

**Alternative Quick Fix:**
```bash
kubectl -n food-app patch service payment-service -p '{"spec":{"selector":{"app":"payment-service"}}}'
```

</details>

<details><summary>📝 Part 2: Complete Ingress Configuration (Click to expand)</summary>

### Step 1: View Current Ingress

```bash
cat /app/food-deliver.yaml
```

You'll notice:
- ⚠️ `/order-details` path has **wrong port 8005** (should be 8002)
- ❌ Missing `/payment` and `/track-order` paths
- ❌ Missing `ingressClassName` and `host`

### Step 2: Verify Correct Service Ports

```bash
# Check all service ports
kubectl -n food-app get svc

# Specifically check order-service
kubectl -n food-app get svc order-service -o yaml | grep -A3 ports
```

**Correct ports:**
- menu-service: 8001
- order-service: 8002 ⚠️ (manifest has 8005 - WRONG!)
- payment-service: 8003
- tracking-service: 8004

### Step 3: Edit the File

```bash
nano /app/food-deliver.yaml
```

Or:
```bash
vi /app/food-deliver.yaml
```

### Step 4: Complete Configuration

Replace the content with:

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

### Step 5: Apply the Configuration

```bash
kubectl apply -f /app/food-deliver.yaml
```

### Step 6: Verify Ingress

```bash
kubectl -n food-app get ingress food-app-ingress
kubectl -n food-app describe ingress food-app-ingress
```

</details>

<details><summary>✅ Part 3: Test All Endpoints (Click to expand)</summary>

### Test Menu Service

```bash
curl http://fast.delivery.io:32080/menu
```

**Expected**: JSON with menu categories and items.

### Test Order Service

```bash
curl http://fast.delivery.io:32080/order-details
```

**Expected**: JSON with order details (order_id, customer, items, status).

### Test Payment Service

```bash
curl http://fast.delivery.io:32080/payment
```

**Expected**: JSON with payment transaction details.

### Test Tracking Service

```bash
curl http://fast.delivery.io:32080/track-order
```

**Expected**: JSON with delivery tracking information.

### Test All at Once

```bash
echo "Testing Menu Service:"
curl -s http://fast.delivery.io:32080/menu | jq -r '.restaurant'

echo -e "\nTesting Order Service:"
curl -s http://fast.delivery.io:32080/order-details | jq -r '.customer'

echo -e "\nTesting Payment Service:"
curl -s http://fast.delivery.io:32080/payment | jq -r '.status'

echo -e "\nTesting Tracking Service:"
curl -s http://fast.delivery.io:32080/track-order | jq -r '.driver_name'
```

</details>

</details>

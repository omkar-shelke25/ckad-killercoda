<details><summary>Issue: /order-details endpoint returns 503 or connection error</summary>

```bash
# Check the Ingress configuration
kubectl -n food-app get ingress food-app-ingress -o yaml | grep -A10 order-details

# Verify the correct service port
kubectl -n food-app get svc order-service

# The port in Ingress should be 8002, not 8005
# If wrong, edit /app/food-deliver.yaml and fix it
```

</details># 🔧 Fix Service Selectors and Configure Ingress

> ⏳ Wait for 2 minutes for the environment to be ready before starting.

## 📋 Mission Brief

The Food Delivery App is partially deployed in the `food-app` namespace. However, there are several issues:
- ❌ Payment service has incorrect selector
- ❌ Ingress configuration has wrong port for `/order-details`
- ❌ Ingress configuration is incomplete (missing paths)

### 🎯 Current State
- **Namespace**: `food-app`
- **Services Running**: menu-service, order-service, payment-service (broken), tracking-service
- **Ingress File**: `/app/food-deliver.yaml` (incomplete with errors)
- **DNS**: ✅ Already configured (`fast.delivery.io` → `172.30.2.2`)

---

## 📝 Task Requirements

### Part 1: Debug and Fix Payment Service Selector ⚠️

The `payment-service` has a wrong selector and is not routing traffic to pods.

**Your Task:**
1. Investigate why the payment service has no endpoints
2. Fix the service selector to match the pod labels
3. Verify the service has endpoints after the fix

**Hints:**
```bash
# Check service endpoints
kubectl -n food-app get endpoints payment-service

# Check pod labels
kubectl -n food-app get pods --show-labels | grep payment

# Compare service selector with pod labels
kubectl -n food-app get service payment-service -o yaml | grep -A2 selector

# Edit the service
kubectl -n food-app edit service payment-service
```

---

### Part 2: Complete the Ingress Configuration

A manifest file is located at `/app/food-deliver.yaml` with partial Ingress configuration.

**Your Task:**

Edit `/app/food-deliver.yaml` and:

1. ✅ Validate and fix existing paths:
   - `/menu` → `menu-service:8001` ✓ (correct)
   - `/order-details` → `order-service:8002` ⚠️ (check the port!)

2. ✅ Add missing paths:
   - `/payment` → `payment-service:8003`
   - `/track-order` → `tracking-service:8004`

3. ✅ Add Ingress configuration:
   - `ingressClassName: traefik`
   - `host: fast.delivery.io`

4. ✅ Apply the manifest:
```bash
kubectl apply -f /app/food-deliver.yaml
```

---

### Part 3: Verify All Endpoints

Test all four endpoints using curl:

```bash
curl http://fast.delivery.io:32080/menu
curl http://fast.delivery.io:32080/order-details
curl http://fast.delivery.io:32080/payment
curl http://fast.delivery.io:32080/track-order
```

---

## 💡 Complete Solution

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

---

## ✅ Success Criteria

After completion, you should have:

1. ✅ **Payment service selector fixed** - Changed from `app: payments` to `app: payment-service`
2. ✅ **Service has 2 endpoints** - Verified with `kubectl get endpoints`
3. ✅ **Ingress port corrected** - `/order-details` changed from port 8005 to 8002
4. ✅ **Ingress resource updated** with:
   - `ingressClassName: traefik`
   - `host: fast.delivery.io`
   - All 4 paths configured correctly with correct ports
5. ✅ **All endpoints accessible**:
   - `/menu` → Returns menu categories
   - `/order-details` → Returns order information
   - `/payment` → Returns payment details
   - `/track-order` → Returns tracking information

---

## 🔍 Troubleshooting

<details><summary>Issue: Payment service still has no endpoints</summary>

```bash
# Check if pods are running
kubectl -n food-app get pods -l app=payment-service

# Check pod labels match service selector
kubectl -n food-app get pods --show-labels | grep payment

# Verify service selector
kubectl -n food-app get service payment-service -o jsonpath='{.spec.selector}'
```

</details>

<details><summary>Issue: Ingress not routing traffic</summary>

```bash
# Check Ingress status
kubectl -n food-app get ingress

# Check Traefik is running
kubectl -n traefik get pods

# Verify Ingress rules
kubectl -n food-app describe ingress food-app-ingress
```

</details>

<details><summary>Issue: curl returns "Could not resolve host"</summary>

```bash
# Verify /etc/hosts entry (should already be configured)
grep fast.delivery.io /etc/hosts

# Should show: 172.30.2.2 fast.delivery.io
```

</details>

---

## 📚 Additional Commands

```bash
# View all resources in food-app namespace
kubectl -n food-app get all

# Check all service endpoints
kubectl -n food-app get endpoints

# View Traefik logs
kubectl -n traefik logs -l app.kubernetes.io/name=traefik --tail=50

# Test without DNS (direct IP)
curl -H "Host: fast.delivery.io" http://172.30.2.2:32080/menu
```

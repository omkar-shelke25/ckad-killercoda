# 🔧 Create Ingress with Multiple Path Routing
> Wait for 2 minutes for the LoadBalancer to set up for Ingress.

## 📋 Mission Brief

The Node.js application is running in the `node-app` namespace with two endpoints: `/terminal` and `/app`. Your task is to create an Ingress resource with path-based routing to expose both endpoints via a custom domain.

### 🎯 Current State
- **Namespace**: `node-app`
- **Deployment**: `multi-endpoint-app` (1 replica)
- **Service**: `multi-endpoint-service` (ClusterIP, Port 80 → 3000)

### 📝 Task Requirements

#### Part 1: Create Ingress Resource
Create an Ingress named `multi-endpoint-ingress` in the `node-app` namespace with:
- ✅ **Name**: `multi-endpoint-ingress`
- ✅ **Namespace**: `node-app`
- ✅ **IngressClassName**: `nginx`
- ✅ **Host**: `node.app.terminal.io`
- ✅ **Path 1**: `/terminal` (Prefix) → `multi-endpoint-service:80`
- ✅ **Path 2**: `/app` (Prefix) → `multi-endpoint-service:80`

#### Part 2: Configure DNS Resolution
- ✅ Add DNS entry to `/etc/hosts` for `node.app.terminal.io`
- ✅ Point to the Ingress Controller's external IP. Ensure that the ingress `multi-endpoint-ingress` has obtained an IP address.

#### Part 3: Verify Access
- ✅ Use `curl` to test `/terminal` endpoint
- ✅ Use `curl` to test `/app` endpoint
- ✅ Confirm both endpoints respond correctly

---

## 💡 Try It Yourself First!

<details><summary>📋 Complete Solution (Click to expand)</summary>

### Step 1: Get Ingress Controller IP

First, find the external IP of the NGINX Ingress Controller:

```bash
kubectl get service -n ingress-nginx ingress-nginx-controller
```

Store the EXTERNAL-IP (should be from MetalLB pool: 192.168.1.240-250):

```bash
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress Controller IP: $INGRESS_IP"
```

### Step 2: Create the Ingress Resource

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-endpoint-ingress
  namespace: node-app
spec:
  ingressClassName: nginx
  rules:
  - host: node.app.terminal.io
    http:
      paths:
      - path: /terminal
        pathType: Prefix
        backend:
          service:
            name: multi-endpoint-service
            port:
              number: 80
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: multi-endpoint-service
            port:
              number: 80
EOF
```

### Step 3: Configure DNS in /etc/hosts

Add the DNS entry to your hosts file:

```bash
# Get the Ingress IP
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Add to /etc/hosts
echo "$INGRESS_IP node.app.terminal.io" | sudo tee -a /etc/hosts
```

**OR** manually edit the file:

```bash
sudo nano /etc/hosts
```

Add this line:
```
<INGRESS_IP>  node.app.terminal.io
```

### Step 4: Verify the Ingress Configuration

Check that the Ingress was created successfully:

```bash
# View Ingress resource
kubectl -n node-app get ingress multi-endpoint-ingress

# Describe Ingress for details
kubectl -n node-app describe ingress multi-endpoint-ingress

# Check Ingress rules
kubectl -n node-app get ingress multi-endpoint-ingress -o yaml
```

You should see output showing:
- Host: `node.app.terminal.io`
- Two paths: `/terminal` and `/app`
- Backend: `multi-endpoint-service:80`

### Step 5: Test Both Endpoints Using curl

#### Test /terminal endpoint:

```bash
# Basic curl test
curl http://node.app.terminal.io/terminal

# Verbose test to see headers
curl -v http://node.app.terminal.io/terminal

# Alternative: Test with Host header
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -H "Host: node.app.terminal.io" http://$INGRESS_IP/terminal
```

**Expected output**: HTML page with terminal-style interface showing:
- "$ Terminal Endpoint"
- Pod hostname
- Status: Running
- Timestamp

#### Test /app endpoint:

```bash
# Basic curl test
curl http://node.app.terminal.io/app

# Verbose test
curl -v http://node.app.terminal.io/app

# Alternative: Test with Host header
curl -H "Host: node.app.terminal.io" http://$INGRESS_IP/app
```

**Expected output**: HTML page with application dashboard showing:
- "Application Dashboard"
- Pod Name
- Status: Active
- Version: 1.0.0

### Step 6: Additional Verification

```bash
# Check service endpoints
kubectl -n node-app get endpoints multi-endpoint-service

# View pod logs
kubectl -n node-app logs -l app=multi-endpoint

# Check Ingress Controller logs (if issues)
kubectl -n ingress-nginx logs -l app.kubernetes.io/component=controller --tail=50

# Test accessing root path (should return 404)
curl http://node.app.terminal.io/
```

### Step 7: Test Both Endpoints in Browser (Optional)

If you have a browser available:

```bash
# Get the Ingress IP
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Access URLs:"
echo "  Terminal: http://node.app.terminal.io/terminal"
echo "  App:      http://node.app.terminal.io/app"
```

---

### ✅ Success Criteria

After completion, you should have:

1. **Ingress resource `multi-endpoint-ingress` created** in `node-app` namespace
2. **IngressClassName set to `nginx`**
3. **Host configured as `node.app.terminal.io`**
4. **Two path rules configured**:
   - `/terminal` → `multi-endpoint-service:80`
   - `/app` → `multi-endpoint-service:80`
5. **PathType set to `Prefix` for both paths**
6. **DNS entry added to `/etc/hosts`**
7. **Successful curl response for `/terminal`** showing terminal interface
8. **Successful curl response for `/app`** showing application dashboard

</details>




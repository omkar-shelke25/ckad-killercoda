## 🦸 CKA - Configure Ingress with TLS

> Wait a 2 minutes for MetalLB to set up.

### 📖 Problem Statement

U.A. High School is deploying a public Hero Registration Portal with two backend services:
- `/register` → `register-service` on port 80
- `/verify` → `verify-service` on port 80

The portal must be accessible at: `heroes.ua-academy.com`

Izuku Midoriya wants all hero data protected with TLS.

**Task:**

Create an Ingress named `hero-reg-ingress` in namespace `class-1a` that:
1. Uses TLS termination with secret `ua-heroes-tls`
2. Routes:
   - `heroes.ua-academy.com/register` → `register-service`
   - `heroes.ua-academy.com/verify` → `verify-service`
3. Configure the DNS entry in `/etc/hosts` based on the Ingress LoadBalancer IP

>  curl -k -v https://heroes.ua-academy.com/register | jq

> curl -k -v https://heroes.ua-academy.com/verify | jq
---

### ✅ Solution

<details><summary>Click to view complete solution</summary>

#### Create Ingress Resource

```bash
cat > hero-reg-ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hero-reg-ingress
  namespace: class-1a
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - heroes.ua-academy.com
    secretName: ua-heroes-tls
  rules:
  - host: heroes.ua-academy.com
    http:
      paths:
      - path: /register
        pathType: Prefix
        backend:
          service:
            name: register-service
            port:
              number: 80
      - path: /verify
        pathType: Prefix
        backend:
          service:
            name: verify-service
            port:
              number: 80
EOF

# Apply the Ingress
kubectl apply -f hero-reg-ingress.yaml
```

#### Verify Ingress

```bash
# Check Ingress status
kubectl get ingress hero-reg-ingress -n class-1a

# View Ingress details
kubectl describe ingress hero-reg-ingress -n class-1a

# Get Ingress IP
kubectl get ingress hero-reg-ingress -n class-1a -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

#### Configure DNS and Test

```bash
# Get Ingress IP
INGRESS_IP=$(kubectl get ingress hero-reg-ingress -n class-1a -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Add to /etc/hosts
echo "${INGRESS_IP} heroes.ua-academy.com" | sudo tee -a /etc/hosts

# Test /register endpoint
curl -k https://heroes.ua-academy.com/register

# Test /verify endpoint
curl -k https://heroes.ua-academy.com/verify
```

#### Verification Commands

```bash
# Check all resources
kubectl get ingress,svc,pods -n class-1a

# View Ingress YAML
kubectl get ingress hero-reg-ingress -n class-1a -o yaml

# Check TLS secret
kubectl get secret ua-heroes-tls -n class-1a

# Test HTTPS access
curl -k -v https://heroes.ua-academy.com/register
curl -k -v https://heroes.ua-academy.com/verify
```

</details>

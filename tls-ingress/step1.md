# CKAD: Configure Ingress with TLS

### Reference Docs
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)

---

## Context

A Hero Registration Portal needs to go live with two backend services:

- `/register` → `register-service` on port 80
- `/verify` → `verify-service` on port 80

The portal must be reachable at `heroes.ua-academy.com` over HTTPS.

> Setup installs an NGINX Ingress Controller and MetalLB, which can take a minute or two to finish provisioning a LoadBalancer IP. If `kubectl get svc -n ingress-nginx` shows `<pending>` under `EXTERNAL-IP`, wait and check again before testing with `curl`.

## Task

Create an Ingress named **`hero-reg-ingress`** in namespace **`class-1a`** that:

1. Uses `ingressClassName: nginx` (the cluster's Ingress Controller is NGINX — without this field set correctly, the controller won't pick up the resource)
2. Uses TLS termination with secret **`ua-heroes-tls`** for host `heroes.ua-academy.com`
3. Routes `heroes.ua-academy.com/register` → `register-service:80`
4. Routes `heroes.ua-academy.com/verify` → `verify-service:80`

Once applied, point your local DNS at the Ingress LoadBalancer IP and test both routes:

```bash
INGRESS_IP=$(kubectl get ingress hero-reg-ingress -n class-1a -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${INGRESS_IP} heroes.ua-academy.com" | sudo tee -a /etc/hosts

curl -k https://heroes.ua-academy.com/register
curl -k https://heroes.ua-academy.com/verify
```

---

## Solution

Try it yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Step 1: Create the Ingress

```bash
cat > hero-reg-ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hero-reg-ingress       # name the verifier looks for
  namespace: class-1a
spec:
  ingressClassName: nginx      # tells NGINX's controller to handle this Ingress
  tls:
  - hosts:
    - heroes.ua-academy.com    # must match the host below and the cert's CN
    secretName: ua-heroes-tls  # pre-created TLS secret with cert + key
  rules:
  - host: heroes.ua-academy.com
    http:
      paths:
      - path: /register
        pathType: Prefix       # matches /register and any subpath under it
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

kubectl apply -f hero-reg-ingress.yaml
```

### Step 2: Confirm it's set up correctly

```bash
kubectl get ingress hero-reg-ingress -n class-1a
kubectl describe ingress hero-reg-ingress -n class-1a
```

Check that an `ADDRESS` is populated (this is the LoadBalancer IP from MetalLB) — if it's blank, give it another minute.

### Step 3: Point DNS at it and test

```bash
INGRESS_IP=$(kubectl get ingress hero-reg-ingress -n class-1a -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${INGRESS_IP} heroes.ua-academy.com" | sudo tee -a /etc/hosts

# -k skips cert verification since this is a self-signed certificate
curl -k -v https://heroes.ua-academy.com/register
curl -k -v https://heroes.ua-academy.com/verify
```

Both should return a JSON response from their respective service.

</details>

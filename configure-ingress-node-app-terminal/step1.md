# Create an Ingress with Multiple Path Routing

## Scenario

A Node.js application is already running in the `node-app` namespace with two endpoints, `/terminal` and `/app`. Your task is to expose both endpoints externally through a single Ingress, using path-based routing on a custom domain, and then verify that both paths actually work.

Note: it can take a couple of minutes for MetalLB to assign an external IP to the Ingress Controller after the environment starts. If a step below isn't working yet, wait and retry before assuming something is broken.

## Current State

- Namespace: `node-app`
- Deployment: `multi-endpoint-app` (1 replica)
- Service: `multi-endpoint-service` (ClusterIP, port 80 -> target port 3000)

## Tasks

> Allow 2 minutes after cluster setup before proceeding — the LoadBalancer needs time to initialize.

### 1. Create the Ingress resource

Create an Ingress named `multi-endpoint-ingress` in the `node-app` namespace with:

- IngressClassName: `nginx`
- Host: `node.app.terminal.io`
- Path `/terminal` (type `Prefix`) -> `multi-endpoint-service:80`
- Path `/app` (type `Prefix`) -> `multi-endpoint-service:80`

### 2. Configure DNS resolution

- Add an entry to `/etc/hosts` mapping `node.app.terminal.io` to the Ingress Controller's external IP. You can find this IP on the `ingress-nginx-controller` Service in the `ingress-nginx` namespace (it's assigned by MetalLB).
- Confirm that the Ingress resource itself (`multi-endpoint-ingress`) has also picked up this same IP under its own status. The nginx Ingress Controller publishes its address back onto every Ingress it manages, so this should match the controller's IP once it's ready.

### 3. Verify access

- `curl` the `/terminal` endpoint and confirm it returns HTTP 200 with the terminal-style page.
- `curl` the `/app` endpoint and confirm it returns HTTP 200 with the application dashboard page.
- Optional: `curl` the root path `/` -- this should return 404, since the app only defines `/terminal` and `/app`. That's expected, not a bug.

```bash
curl http://node.app.terminal.io/app
curl http://node.app.terminal.io/terminal
```

---

## Solution

<details><summary>Click to expand</summary>

### Step 1 -- Find the Ingress Controller's external IP

```bash
kubectl get service -n ingress-nginx ingress-nginx-controller
```

Save it to a variable for later use:

```bash
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$INGRESS_IP"
```

This should be an address from the MetalLB pool (`192.168.1.240`-`192.168.1.250`). If it's empty, MetalLB likely hasn't finished assigning an address yet -- wait a bit and try again.

### Step 2 -- Create the Ingress

```bash
cat <<INGRESS_YAML | kubectl apply -f -
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
INGRESS_YAML
```

Confirm the Ingress itself has picked up an address (this should match `$INGRESS_IP`):

```bash
kubectl -n node-app get ingress multi-endpoint-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo
```

If this prints nothing, give it a few seconds -- the controller needs a moment to publish the address back onto the Ingress object -- then check again.

### Step 3 -- Add the DNS entry

```bash
echo "$INGRESS_IP node.app.terminal.io" | sudo tee -a /etc/hosts
```

Or edit the file directly:

```bash
sudo nano /etc/hosts
```

and add:

```
<INGRESS_IP>  node.app.terminal.io
```

### Step 4 -- Sanity-check the Ingress configuration

```bash
kubectl -n node-app get ingress multi-endpoint-ingress
kubectl -n node-app describe ingress multi-endpoint-ingress
```

You should see the host `node.app.terminal.io`, both paths (`/terminal`, `/app`), and `multi-endpoint-service:80` as the backend for each.

### Step 5 -- Test both endpoints

```bash
curl http://node.app.terminal.io/terminal
curl http://node.app.terminal.io/app
```

Expected for `/terminal`: an HTML page containing "Terminal Endpoint", the pod hostname, status, and a timestamp.

Expected for `/app`: an HTML page containing "Application Dashboard", the pod name, status, and version.

If `curl` can't resolve the hostname, double-check `/etc/hosts`. If it resolves but times out or connection is refused, double-check the Ingress Controller's external IP and that the Ingress has a status address (Step 2).

You can also bypass DNS and hit the controller IP directly with an explicit `Host` header, which is useful for isolating DNS issues from Ingress/routing issues:

```bash
curl -H "Host: node.app.terminal.io" "http://$INGRESS_IP/terminal"
curl -H "Host: node.app.terminal.io" "http://$INGRESS_IP/app"
```

### Step 6 -- Optional checks

```bash
# Confirm the service has a healthy endpoint
kubectl -n node-app get endpoints multi-endpoint-service

# Check the app's logs
kubectl -n node-app logs -l app=multi-endpoint

# Check the Ingress Controller's logs if something looks wrong
kubectl -n ingress-nginx logs -l app.kubernetes.io/component=controller --tail=50

# Root path should return 404 -- this is expected
curl -i http://node.app.terminal.io/
```

</details>


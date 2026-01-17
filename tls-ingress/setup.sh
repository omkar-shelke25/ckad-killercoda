#!/bin/bash
set -euo pipefail

echo "🦸 Setting up U.A. High School Hero Registration Portal..."
echo ""

# Install NGINX Ingress Controller
echo "🔧 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml > /dev/null 2>&1

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s > /dev/null 2>&1 || echo "Ingress controller initializing..."

sleep 5

# Install MetalLB for LoadBalancer support
echo "🔧 Installing MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml > /dev/null 2>&1

echo "⏳ Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s > /dev/null 2>&1 || echo "Waiting for MetalLB..."

sleep 5

echo "🌐 Configuring MetalLB IP Address Pool..."
cat <<'YAML' | kubectl apply -f - > /dev/null 2>&1
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-address-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-address-pool
YAML

sleep 5

# Create class-1a namespace
echo "🏗️ Creating class-1a namespace..."
kubectl create namespace class-1a > /dev/null 2>&1 || true

# Create TLS certificate
echo "🔒 Creating TLS certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key \
  -out /tmp/tls.crt \
  -subj "/CN=heroes.ua-academy.com/O=UA-High-School" > /dev/null 2>&1

kubectl create secret tls ua-heroes-tls \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  -n class-1a > /dev/null 2>&1 || true

sleep 1

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: register-app
  namespace: class-1a
data:
  app.py: |
    import json
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            response = {
                "service": "register-service 📝",
                "status": "online ✅",
                "message": "Register hero quirks here! ✨",
                "school": "U.A. High School 🏫"
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

    if __name__ == "__main__":
        print("🚀 Register Service running on port 80")
        server = HTTPServer(("", 80), Handler)
        server.serve_forever()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: register-service
  namespace: class-1a
  # annotation may contain emoji text; labels must be ASCII-safe
  annotations:
    icon: "📝"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: register
  template:
    metadata:
      labels:
        app: register
        # keep a safe ASCII label if you need an 'icon' label for selectors, metrics, etc.
        icon: "memo"
    spec:
      containers:
      - name: register-python
        image: python:3.11-alpine
        command: ["python", "/app/app.py"]
        volumeMounts:
        - name: register-code
          mountPath: /app
        ports:
        - containerPort: 80
      volumes:
      - name: register-code
        configMap:
          name: register-app
---
apiVersion: v1
kind: Service
metadata:
  name: register-service
  namespace: class-1a
  annotations:
    icon: "📝"
  labels:
    app: register
    icon: "memo"
spec:
  type: ClusterIP
  selector:
    app: register
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: verify-app
  namespace: class-1a
data:
  app.py: |
    import json
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            response = {
                "service": "verify-service 🔍",
                "status": "online ✅",
                "message": "Verify hero licenses here! 🛡️",
                "school": "U.A. High School 🏫"
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

    if __name__ == "__main__":
        print("🔍 Verify Service running on port 80")
        server = HTTPServer(("", 80), Handler)
        server.serve_forever()
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: verify-service
  namespace: class-1a
  annotations:
    icon: "🔍"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: verify
  template:
    metadata:
      labels:
        app: verify
        icon: "search"
    spec:
      containers:
      - name: verify-python
        image: python:3.11-alpine
        command: ["python", "/app/app.py"]
        volumeMounts:
        - name: verify-code
          mountPath: /app
        ports:
        - containerPort: 80
      volumes:
      - name: verify-code
        configMap:
          name: verify-app
---
apiVersion: v1
kind: Service
metadata:
  name: verify-service
  namespace: class-1a
  annotations:
    icon: "🔍"
  labels:
    app: verify
    icon: "search"
spec:
  type: ClusterIP
  selector:
    app: verify
  ports:
  - port: 80
    targetPort: 80
EOF


# Wait for deployments
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=available deployment/register-service -n class-1a --timeout=120s > /dev/null 2>&1
kubectl wait --for=condition=available deployment/verify-service -n class-1a --timeout=120s > /dev/null 2>&1

echo ""
echo "=========================================================================="
echo "   U.A. HIGH SCHOOL - HERO REGISTRATION PORTAL"
echo "=========================================================================="
echo ""
echo "ENVIRONMENT READY:"
echo "   - Namespace: class-1a"
echo "   - Services: register-service, verify-service"
echo "   - TLS Secret: ua-heroes-tls"
echo "   - Hostname: heroes.ua-academy.com"
echo ""
echo "YOUR TASK:"
echo ""
echo "Create an Ingress named 'hero-reg-ingress' that:"
echo "   1. Uses TLS termination with secret 'ua-heroes-tls'"
echo "   2. Routes /register to register-service:80"
echo "   3. Routes /verify to verify-service:80"
echo "   4. Hostname: heroes.ua-academy.com"
echo ""
echo "SERVICES STATUS:"
kubectl get svc -n class-1a
echo ""
echo "TLS SECRET:"
kubectl get secret ua-heroes-tls -n class-1a
echo ""
echo "TIME LIMIT: 6-8 minutes"
echo "Plus Ultra! 💪"
echo ""
echo "=========================================================================="

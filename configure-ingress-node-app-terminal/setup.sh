#!/bin/bash
set -euo pipefail

echo "🚀 Setting up multi-endpoint application environment..."

NAMESPACE="node-app"

# Create namespace
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s 2>/dev/null || echo "Waiting for ingress controller..."

sleep 3

echo "🔧 Installing MetalLB for LoadBalancer support..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

echo "⏳ Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s 2>/dev/null || echo "Waiting for MetalLB..."

sleep 5

echo "🌐 Configuring MetalLB IP Address Pool..."
cat <<'YAML' | kubectl apply -f -
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

echo "🚀 Deploying Multi-Endpoint Node.js Application..."

# Use a quoted here-doc so shell won't expand JS ${...}, then envsubst only for ${NAMESPACE}
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-endpoint-app
  namespace: node-app
  labels:
    app: multi-endpoint
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-endpoint
  template:
    metadata:
      labels:
        app: multi-endpoint
    spec:
      containers:
      - name: app-container
        image: node:18-alpine
        ports:
        - containerPort: 3000
        command: ["/bin/sh"]
        args:
          - -c
          - |
            cat > /server.js <<'EOFJS'
            const http = require('http');
            const url = require('url');

            const server = http.createServer((req, res) => {
              const pathname = url.parse(req.url).pathname;
              
              if (pathname === '/terminal') {
                res.writeHead(200, { 'Content-Type': 'text/html' });
                res.end(`
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <title>Terminal</title>
                    <style>
                      body { 
                        margin: 0; 
                        padding: 20px; 
                        background: #1e1e1e; 
                        color: #00ff00; 
                        font-family: 'Courier New', monospace; 
                      }
                      .terminal { 
                        background: #000; 
                        padding: 20px; 
                        border-radius: 5px; 
                        border: 2px solid #00ff00;
                      }
                      h1 { color: #00ff00; }
                    </style>
                  </head>
                  <body>
                    <div class="terminal">
                      <h1>$ Terminal Endpoint</h1>
                      <p>&gt; System initialized...</p>
                      <p>&gt; Pod: ${process.env.HOSTNAME || 'local'}</p>
                      <p>&gt; Status: Running</p>
                      <p>&gt; Timestamp: ${new Date().toISOString()}</p>
                    </div>
                  </body>
                  </html>
                `);
              } else if (pathname === '/app') {
                res.writeHead(200, { 'Content-Type': 'text/html' });
                res.end(`
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <title>Application</title>
                    <style>
                      body { 
                        margin: 0; 
                        padding: 20px; 
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        font-family: Arial, sans-serif;
                        color: white;
                      }
                      .container { 
                        max-width: 800px; 
                        margin: 50px auto; 
                        background: rgba(255,255,255,0.1); 
                        padding: 30px; 
                        border-radius: 10px;
                        backdrop-filter: blur(10px);
                      }
                      h1 { margin-top: 0; }
                    </style>
                  </head>
                  <body>
                    <div class="container">
                      <h1>Application Dashboard</h1>
                      <p><strong>Pod Name:</strong> ${process.env.HOSTNAME || 'local'}</p>
                      <p><strong>Status:</strong> Active</p>
                      <p><strong>Version:</strong> 1.0.0</p>
                      <p><strong>Timestamp:</strong> ${new Date().toLocaleString()}</p>
                    </div>
                  </body>
                  </html>
                `);
              } else {
                res.writeHead(404, { 'Content-Type': 'text/plain' });
                res.end('404 - Not Found\n\nAvailable endpoints:\n- /terminal\n- /app');
              }
            });

            server.listen(3000, () => {
              console.log('Server running on port 3000');
              console.log('Endpoints available:');
              console.log('  - /terminal');
              console.log('  - /app');
            });
            EOFJS
            node /server.js
---
apiVersion: v1
kind: Service
metadata:
  name: multi-endpoint-service
  namespace: node-app
spec:
  selector:
    app: multi-endpoint
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
YAML

kubectl -n ingress-nginx patch svc ingress-nginx-controller \
  -p '{"spec":{"type":"LoadBalancer"}}' --type=merge


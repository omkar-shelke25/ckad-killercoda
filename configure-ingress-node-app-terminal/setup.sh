#!/bin/bash
set -euo pipefail

echo "🚀 Setting up multi-endpoint application environment..."

NAMESPACE="node-app"
METALLB_POOL="192.168.1.240-192.168.1.250"
NODE_IMAGE="node:18-alpine" # stable explicit tag

# Create namespace if not exists
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s >/dev/null 2>&1 || echo "Ingress controller may still be starting (check: kubectl -n ingress-nginx get pods)"

sleep 8

echo "🔧 Installing MetalLB for LoadBalancer support..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

echo "⏳ Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s >/dev/null 2>&1 || echo "MetalLB controller may still be starting (check: kubectl -n metallb-system get pods)"

sleep 6

echo "🌐 Configuring MetalLB IP Address Pool..."
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-address-pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_POOL}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-address-pool
EOF

sleep 4

echo "🚀 Deploying Multi-Endpoint Node.js Application..."

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-endpoint-app
  namespace: ${NAMESPACE}
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
        image: ${NODE_IMAGE}
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
  namespace: ${NAMESPACE}
spec:
  selector:
    app: multi-endpoint
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
EOF

echo "⏳ Waiting for deployment to be ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/multi-endpoint-app --timeout=120s || echo "Rollout may still be progressing (check pod logs)"

echo "⏳ Waiting for LoadBalancer IP assignment..."
# Wait up to 60s for external IP (MetalLB)
LB_IP=""
for i in {1..30}; do
  LB_IP=$(kubectl -n "${NAMESPACE}" get svc multi-endpoint-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -n "$LB_IP" && "$LB_IP" != "<none>" ]]; then
    break
  fi
  sleep 2
done

echo ""
if [[ -z "$LB_IP" ]]; then
  echo "⚠️  No External IP found for service multi-endpoint-service. Check MetalLB and service resources:"
  kubectl -n "${NAMESPACE}" get svc multi-endpoint-service -o wide
  kubectl -n metallb-system get pods
  exit 1
else
  echo "✅ Service External IP: ${LB_IP}"
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "📊 Current deployment status:"
kubectl -n "${NAMESPACE}" get deployment multi-endpoint-app
echo ""
echo "🌐 Current service:"
kubectl -n "${NAMESPACE}" get service multi-endpoint-service
echo ""
echo "📦 Running pods:"
kubectl -n "${NAMESPACE}" get pods -l app=multi-endpoint
echo ""
echo "⚠️  Current Issues (if any):"
echo "   • No Ingress resource configured"
echo "   • Application endpoints not accessible via custom domain (create Ingress and add DNS / /etc/hosts entry)"
echo ""
echo "🎯 Your Mission (next steps):"
echo "   1. Create an Ingress resource named 'multi-endpoint-ingress' (path-based for /terminal and /app)"
echo "   2. Map a DNS name (example: node.app.terminal.io) to the External IP: ${LB_IP}"
echo "   3. Verify both endpoints using curl commands:"
echo "      curl http://${LB_IP}/terminal"
echo "      curl http://${LB_IP}/app"
echo ""
echo "If you want, I can now append an Ingress resource to this script (and optionally add /etc/hosts)."

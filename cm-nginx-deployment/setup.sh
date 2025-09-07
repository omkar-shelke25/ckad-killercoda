#!/bin/bash
set -e

# Create the moon namespace
kubectl create namespace moon

# Create the nginx configuration file
mkdir -p /opt/course/15
cat > /opt/course/15/web-moon.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Web Moon Server</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background-color: #1a1a2e;
            color: #eee;
            text-align: center;
            padding: 50px;
        }
        h1 { color: #16213e; }
        .moon { 
            font-size: 4em; 
            color: #f39c12;
        }
    </style>
</head>
<body>
    <div class="moon">🌙</div>
    <h1>Welcome to Web Moon</h1>
    <p>Team Moonpie's Nginx Server</p>
    <p>Powered by Kubernetes ConfigMap</p>
</body>
</html>
EOF

# Create the nginx Deployment (configured to use the ConfigMap)
cat > /tmp/web-moon-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-moon
  namespace: moon
  labels:
    app: web-moon
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-moon
  template:
    metadata:
      labels:
        app: web-moon
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-config
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: html-config
        configMap:
          name: configmap-web-moon-html
EOF

# Apply the incomplete Deployment
kubectl apply -f /tmp/web-moon-deployment.yaml

# Wait for the Deployment to be created (it will be running but without the config)
sleep 2

# Create a Service for the Deployment
kubectl expose deployment web-moon -n moon --port=80 --target-port=80 --type=ClusterIP

echo "✅ Setup complete. Namespace 'moon' created with nginx Deployment 'web-moon'."
echo "📄 Configuration file available at /opt/course/15/web-moon.html"
echo "🎯 Task: Create ConfigMap 'configmap-web-moon-html' with the HTML content."
echo "📝 The Deployment is already configured to use this ConfigMap once created."

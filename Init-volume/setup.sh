#!/bin/bash
set -e

# Create the course directory
mkdir -p /opt/course/17

# Create the initial Deployment YAML with nginx but empty volume
cat > /opt/course/17/test-init-container.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: default
  labels:
    app: test-init-container
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-init-container
  template:
    metadata:
      labels:
        app: test-init-container
    spec:
      containers:
      - name: nginx
        image: nginx:1.17.3-alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: web-content
        emptyDir: {}
EOF

# Create a sample HTML content that should be created by the InitContainer
cat > /tmp/sample-index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>InitContainer Magic</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 50px;
            margin: 0;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            max-width: 600px;
            margin: 0 auto;
        }
        .emoji { font-size: 4em; margin: 20px 0; }
        h1 { margin: 20px 0; font-size: 2.5em; }
        p { font-size: 1.2em; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>InitContainer Success!</h1>
        <p>This content was created by an InitContainer</p>
        <p>The main nginx container is now serving files prepared during initialization</p>
        <div class="emoji">✨</div>
        <p><strong>check this out!</strong></p>
    </div>
</body>
</html>
EOF

echo "✅ Setup complete!"
echo "📁 Deployment YAML created at: /opt/course/17/test-init-container.yaml"
echo "📄 Sample HTML content available at: /tmp/sample-index.html (for reference)"
echo "🎯 Your task: Add an InitContainer to prepare content in the shared volume"

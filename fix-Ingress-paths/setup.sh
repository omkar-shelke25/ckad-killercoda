#!/bin/bash
set -e

TRAEFIK_NS="traefik"
FOOD_NS="food-app"
HTTP_NODEPORT=32080
HTTPS_NODEPORT=32443
DOMAIN="fast.delivery.io"

echo "🍜 Setting up Food Delivery App environment..."

# ==============================
# Install Traefik
# ==============================
echo "📦 Installing Traefik Ingress Controller..."
kubectl create namespace ${TRAEFIK_NS} 2>/dev/null || true

helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

echo "🚀 Installing Traefik (NodePort mode)..."
helm install traefik traefik/traefik \
  --namespace ${TRAEFIK_NS} \
  --set service.type=NodePort \
  --set ports.web.nodePort=${HTTP_NODEPORT} \
  --set ports.websecure.nodePort=${HTTPS_NODEPORT} \
  --wait --timeout=120s >/dev/null 2>&1

echo "✅ Traefik installed successfully"
sleep 3

# ==============================
# Create Namespace
# ==============================
echo "🥢 Creating namespace '${FOOD_NS}'..."
kubectl create namespace ${FOOD_NS} 2>/dev/null || true

# ==============================
# Deploy Services with INTENTIONAL ERRORS
# ==============================
echo "🍣 Deploying FastAPI microservices..."

# --- MENU SERVICE ---
kubectl -n ${FOOD_NS} apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: menu-service-config
data:
  main.py: |
    from fastapi import FastAPI
    from datetime import datetime
    app = FastAPI(title="🍽️ Menu Service")

    @app.get("/")
    def home():
        return {
            "message": "🍽️ Menu Service is live!",
            "timestamp": datetime.now().isoformat(),
            "info": "Serving today's special Japanese and global cuisine 🍣🍔🥗"
        }

    @app.get("/menu")
    def menu():
        return {
            "restaurant": "Tokyo Dine & Go 🇯🇵",
            "updated_at": datetime.now().isoformat(),
            "categories": [
                {"name": "🍱 Bento Boxes", "items": ["Sushi Bento", "Ramen Deluxe", "Katsu Curry"]},
                {"name": "🍔 Western", "items": ["Cheese Burger", "Veggie Pizza", "Grilled Sandwich"]},
                {"name": "☕ Beverages", "items": ["Matcha Latte", "Iced Coffee", "Lemon Tea"]}
            ]
        }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: menu-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: menu-service
  template:
    metadata:
      labels:
        app: menu-service
    spec:
      volumes:
      - name: app
        configMap:
          name: menu-service-config
      containers:
      - name: menu
        image: tiangolo/uvicorn-gunicorn-fastapi:python3.11
        command: ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app
          mountPath: /app
---
apiVersion: v1
kind: Service
metadata:
  name: menu-service
spec:
  selector:
    app: menu-service
  ports:
  - port: 8001
    targetPort: 80
EOF

# --- ORDER SERVICE ---
kubectl -n ${FOOD_NS} apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
data:
  main.py: |
    from fastapi import FastAPI
    from datetime import datetime
    app = FastAPI(title="📦 Order Service")

    @app.get("/")
    def home():
        return {"message": "📦 Order Service active", "timestamp": datetime.now().isoformat()}

    @app.get("/order-details")
    def order():
        return {
            "order_id": 20251106,
            "customer": "Yuki Nakamura",
            "items": ["Sushi Bento", "Matcha Latte"],
            "status": "preparing",
            "estimated_delivery": "25 mins",
            "placed_at": datetime.now().isoformat(),
            "message": "📦 Your order is being prepared with care!"
        }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      volumes:
      - name: app
        configMap:
          name: order-service-config
      containers:
      - name: order
        image: tiangolo/uvicorn-gunicorn-fastapi:python3.11
        command: ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app
          mountPath: /app
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
  - port: 8002
    targetPort: 80
EOF

# --- PAYMENT SERVICE (WRONG SELECTOR - INTENTIONAL ERROR) ---
kubectl -n ${FOOD_NS} apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-service-config
data:
  main.py: |
    from fastapi import FastAPI
    from datetime import datetime
    app = FastAPI(title="💳 Payment Service")

    @app.get("/")
    def home():
        return {"message": "💳 Payment Service ready", "timestamp": datetime.now().isoformat()}

    @app.get("/payment")
    def payment():
        return {
            "transaction_id": "TXNJP-20251106-001",
            "amount": "¥8,990",
            "currency": "JPY",
            "method": "PayPay / Konbini",
            "location": "Shibuya, Tokyo 🇯🇵",
            "status": "success ✅",
            "processed_at": datetime.now().isoformat(),
            "message": "💳 Payment successful! Enjoy your meal 🍣"
        }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      volumes:
      - name: app
        configMap:
          name: payment-service-config
      containers:
      - name: payment
        image: tiangolo/uvicorn-gunicorn-fastapi:python3.11
        command: ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app
          mountPath: /app
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
spec:
  selector:
    app: payments
  ports:
  - port: 8003
    targetPort: 80
EOF

# --- TRACKING SERVICE ---
kubectl -n ${FOOD_NS} apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: tracking-service-config
data:
  main.py: |
    from fastapi import FastAPI
    from datetime import datetime
    app = FastAPI(title="🚚 Tracking Service")

    @app.get("/")
    def home():
        return {"message": "🚚 Tracking Service up and running", "timestamp": datetime.now().isoformat()}

    @app.get("/track-order")
    def track():
        return {
            "order_id": 20251106,
            "driver_name": "Satoshi Tanaka 🚴‍♂️",
            "vehicle_number": "Shinagawa-500-SA 12-34",
            "current_location": "📍 Shinjuku, Tokyo",
            "estimated_arrival": "15 minutes",
            "message": "🚚 Your order is on the way! Please stay ready 🙌"
        }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tracking-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tracking-service
  template:
    metadata:
      labels:
        app: tracking-service
    spec:
      volumes:
      - name: app
        configMap:
          name: tracking-service-config
      containers:
      - name: tracking
        image: tiangolo/uvicorn-gunicorn-fastapi:python3.11
        command: ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app
          mountPath: /app
---
apiVersion: v1
kind: Service
metadata:
  name: tracking-service
spec:
  selector:
    app: tracking-service
  ports:
  - port: 8004
    targetPort: 80
EOF

# ==============================
# Create INCOMPLETE Ingress manifest file (WITH WRONG PORT)
# ==============================
echo "📝 Creating incomplete Ingress manifest at /app/food-deliver.yaml..."
mkdir -p /app

cat > /app/food-deliver.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: food-app-ingress
  namespace: food-app
spec:
  rules:
  - http:
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
              number: 8005
EOF

# ==============================
# Configure DNS Resolution
# ==============================
echo "🌐 Configuring DNS resolution..."
HOST_IP="172.30.2.2"

if grep -q "${DOMAIN}" /etc/hosts; then
  echo "ℹ️  /etc/hosts already contains ${DOMAIN}"
else
  echo "${HOST_IP} ${DOMAIN}" >> /etc/hosts
  echo "✅ Added '${HOST_IP} ${DOMAIN}' to /etc/hosts"
fi

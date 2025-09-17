#!/bin/bash
set -euo pipefail

echo "🚀 Preparing production-like environment..."

NS="payments-prod"
kubectl get ns $NS >/dev/null 2>&1 || kubectl create ns $NS

# Apply a production-style ResourceQuota that enforces requests and limits totals
cat <<'EOF' | kubectl -n $NS apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: rq-payments-prod
spec:
  hard:
    # total requested CPU across the namespace (3 replicas × 200m = 600m)
    requests.cpu: "600m"
    # total requested memory across the namespace (3 × 512Mi = 1536Mi)
    requests.memory: 1536Mi
    # total allowed limits (conservative totals for the namespace)
    limits.cpu: "1"
    limits.memory: 3Gi
EOF

# Deploy a production-like deployment WITHOUT resource requests/limits (this will fail to schedule)
cat <<'EOF' | kubectl -n $NS apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-api
  labels:
    app: checkout-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-api
  template:
    metadata:
      labels:
        app: checkout-api
    spec:
      containers:
      - name: checkout-api
        image: nginx
        ports:
        - containerPort: 80
        # << intentionally no resources block here to simulate the failure condition >>
EOF

echo "✅ Environment created:"
echo "- Namespace: $NS"
echo "- ResourceQuota: rq-payments-prod (requests.cpu=600m, requests.memory=1536Mi, limits.cpu=1, limits.memory=3Gi)"
echo "- Deployment: checkout-api (3 replicas) created WITHOUT resources — pods will not be scheduled until you add requests/limits."

# 🟢 Create Green, then Switch Service (namespace: `ios`)

You have a live deployment named **web-app-blue** running **nginx:1.19** with **3 replicas** in the **ios** namespace. 

Create a new deployment called **web-app-green** running **nginx:1.20** with **3 replicas**, **but do not route traffic to it yet**.

Then, update the existing service **web-app-service** to send traffic to the **green** deployment pods instead of **blue** with **zero downtime**.

---


## 📄 Example YAML for web-app-green
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-green
  namespace: ios
  labels:
    app: web-app
    color: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      color: green
  template:
    metadata:
      labels:
        app: web-app
        color: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5

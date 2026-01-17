# ✅ Blue/Green Switch Completed (namespace: ios)

- 🔵 **web-app-blue**: `nginx:1.19`, 3 replicas (left running)  
- 🟢 **web-app-green**: `nginx:1.20`, 3 replicas (new)  
- 🔀 **web-app-service** selector switched to **color=green** → traffic now goes to GREEN


## 💬 Have a doubt?

🔗 **Discord Link:**
[https://killercoda.com/discord](https://killercoda.com/discord)


**Zero-downtime pattern:** Bring GREEN up and Ready first, then flip the Service selector from BLUE → GREEN.

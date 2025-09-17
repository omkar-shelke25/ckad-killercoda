# 📊 CKAD: Configure Pod Resource Requests for Production Workload

## 🎯 Scenario Overview

You're a DevOps engineer at a growing SaaS company. The platform engineering team needs to deploy a new nginx-based web service that will handle critical customer traffic. To ensure reliable performance and prevent resource starvation, you must configure appropriate resource requests.

## 🏗️ Architecture Goal

```
Namespace: project-one
    ↓
Pod: nginx-resources
    ↓
Container: nginx
├─ CPU Request: 200m
└─ Memory Request: 1Gi
```

Click **Start Scenario** to begin configuring your production workload!

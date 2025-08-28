# 🎉 Rollout / Rollback Complete

You handled a rollout that started **paused**, updated image and replicas while paused, then **resumed** and **rolled back** safely to a known-good nginx version.

Final state:
- Deployment `api-server` uses **nginx:1.25.3**
- Replicas = **3**
- Deployment is **Ready** and **unpaused**

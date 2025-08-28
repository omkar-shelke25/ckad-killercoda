# ✅ Canary Rollout Completed

- 🧱 **Stable**: `frontend` → **nginx:1.19**, **4 replicas**  
- 🐤 **Canary**: `frontend-canary` → **nginx:1.20**, **1 replica**  
- 🔀 Both share the Service `frontend-svc` (`app=frontend`) → ~**20%** canary traffic via endpoint count.

Great job!

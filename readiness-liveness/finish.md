# ✅ Mission Complete!

You successfully configured the warp core probe systems:

- **readinessProbe**: HTTP check on `/readyz` port 80
  - Initial delay: 2 seconds
  - Check interval: 5 seconds
  
- **livenessProbe**: HTTP check on `/helathz` port 80
  - Initial delay: 5 seconds
  - Check interval: 10 seconds
  - Failure threshold: 3

All pods in the **galaxy** namespace are now monitored with health probes, ensuring the warp core stays stable and operational! 🚀


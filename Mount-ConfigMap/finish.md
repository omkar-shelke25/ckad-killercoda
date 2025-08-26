# 🎉 Great job!

You deployed **2 replicas** of an **nginx** workload that reads config **as files** from `/etc/appconfig` via **ConfigMap**, and used a **readinessProbe** to ensure Pods only become Ready when the files contain the exact required values.

**Key takeaways**
- Use **ConfigMap** to provide file-based configuration without changing images.
- Use **`readinessProbe.exec`** to gate readiness on config correctness.

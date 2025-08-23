# Configuring Pod and Container Security Contexts

Security has mandated least-privilege defaults for all workloads:
- Run as a **non-root** user (explicit UID/GID).
- Make the **container root filesystem read-only**.

You’ll deploy a Pod that satisfies both requirements using Kubernetes **SecurityContext** at Pod and Container levels.

Click **Start Scenario** to begin.

# 🎉 Great Job!

You restricted access so **only Pods labeled `role=frontend` can reach the backend on TCP/80**.

## Key Takeaways
- The **target** of the policy is defined by `spec.podSelector` (here: `app=backend`).
- The **allowed sources** go under `ingress.from` (here: `podSelector` with `role=frontend`).
- Always include the **port/protocol** constraints to avoid broader access than intended.

.

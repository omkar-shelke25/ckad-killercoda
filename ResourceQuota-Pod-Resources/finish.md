# Completed

You created:
- Namespace **production-apps**
- ResourceQuota **app-quota** with pod count, CPU, and memory limits
- Deployment **web-server** (3 replicas) using nginx, with resource requests and limits set on each container

All pods are running and ready, and the ResourceQuota's usage matches the specification.

## Key Takeaway

A Deployment's `selector.matchLabels` must match its `template.metadata.labels` — this is enforced by the Kubernetes API itself, not just convention. Whatever label you choose, the verifier reads it from the Deployment's actual selector rather than assuming a fixed name, so any valid, consistent label works.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/ResourceQuota-Pod-Resources)**

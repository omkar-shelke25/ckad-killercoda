# Completed

You deployed the Straw Hat crew database using:

- **ConfigMap** — stored the HTML content
- **InitContainer** — copied that content into a shared volume before the main container started
- **Deployment** — ran Nginx serving the copied content
- **NodePort Service** — exposed it on port 32100

## Key Takeaway

InitContainers run to completion *before* any container in the Pod starts, and they can share volumes with the main container without being part of its running lifecycle. That's what makes the "prepare data, then serve it" pattern work here: the ConfigMap is mounted read-only into the InitContainer, copied into an `emptyDir` volume, and only then does Nginx start serving from that same volume.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/ConfigMap-InitContainer)**

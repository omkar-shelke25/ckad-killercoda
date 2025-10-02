# CKAD: Gargantua (API deprecation + NodePort)

A manifest file is present at `/blackhole/gargantuan-deprecated.yaml`. This manifest was created for Kubernetes v1.30 using a deprecated Deployment API and intentionally **lacks a `selector`**. Your cluster runs v1.33 where that old API is no longer supported.

The application defined in the Deployment serves a single HTML file (`/usr/share/nginx/html/gargantua-scifi.html`) which has been placed at `/blackhole/gargantua-scifi.html` by the setup script.

Your tasks:

- Convert the deprecated manifest to a supported API version (use the official `kubectl convert` plugin — install it if necessary).
- Fix the Deployment (add the required `selector` and any other missing fields) and apply it in the `interstellar` namespace.
- Ensure the Deployment mounts the provided ConfigMap file so the HTML is served by nginx.
- Expose the Deployment with a NodePort Service named `gargantuan-svc` on NodePort **33000** (map `33000 -> 80`).
- Confirm the pods are `Running`, the Service exists with the correct `nodePort`, and the content is present inside a running pod.

# 🚀 CKAD Practice Labs – By Omkar Shelke

A complete collection of **Certified Kubernetes Application Developer (CKAD)** practice labs, designed and authored by **Omkar Shelke**.
Each lab is scenario-driven, exam-focused, and runnable instantly in your browser via KillerCoda.

### 🔗 **Launch Labs on KillerCoda**

👉 **[https://killercoda.com/omkar-shelke25](https://killercoda.com/omkar-shelke25)**

---

# 📘 What’s Inside?

This repository contains **real CKAD-style challenges**, including Pods, Deployments, Services, Ingress, NetworkPolicies, RBAC, CronJobs, ConfigMaps, Secrets, Container lifecycle, and more.

Every scenario mirrors real exam patterns:

✔ Minimal instructions

✔ Hands-on Kubernetes CLI

✔ Exact exam difficulty

✔ Production-style debugging tasks

---

# 📚 **Complete Lab Index**

Below is the full list of CKAD scenarios exactly as you authored them — formatted cleanly and grouped for clarity.

---

## 🏗️ **Container Image Building & Packaging**

* Buildx: Export Docker & OCI Images
* CKAD: Build Image and Save in OCI Format with Podman
* CKAD: Build, Save & Deploy with Podman
* CKAD: Docker Image Build and Export
* Podman Build (podman-build)
* Podman OCI Format (podman-oci-format)

---

## 🔐 **ServiceAccounts, Secrets & Token Management**

* ServiceAccount Secret & Token Decode
* Convert hardcoded env → Kubernetes Secrets
* Multiple ConfigMaps & Secret → env vars
* Secrets via env + volume (Pod update)
* Fix ServiceAccount for Payment API
* RBAC: Read a Specific Secret Only
* RBAC Fix scenarios
* RBAC — Namespaced Pod Viewer
* RBAC — Cluster-wide Node Reader
* RBAC — Pod Logs Only (Cross-namespace Binding)

---

## ⚙️ **Resource Management, QoS & Limits**

* QoS Classes & Resource Management
* Configure Resource Requests & Limits for Deployments
* LimitRange Enforcement
* ResourceQuota + Pod Resources
* ResourceQuota blocking Checkout API
* Convert Pod → Deployment with securityContext

---

## 🚦 **Deployments, Blue-Green, Canary & Rollouts**

* Blue/Green switch (zero downtime)
* Canary rollout (20% weighted traffic)
* Rolling Update + Controlled Rollback
* Update Deployment image + name (in-place)
* Update replicas/image on a paused Deployment
* rollout-pause-resume
* max-min-rollback

---

## 🌐 **Services, DNS, Ingress & Routing**

* ClusterIP Service + Port redirect + Test artifacts
* Fix Ingress 503 with ExternalName
* ExternalName Service Integration
* Ingress Path Rewrite
* Ingress with Default Backend
* DNS + Traefik Ingress (path routing)
* Ingress with multiple path routing (/terminal, /app)
* ingress-routing-ex-svc
* Fix Ingress paths in Food Delivery App

---

## 🛡️ **NetworkPolicy (Beginner → Advanced)**

* Complex NetworkPolicy Pod communication
* Fix Pod communication (without modifying NPs)
* Fix Pod network isolation via labels
* Egress NP with DNS allowance
* DNS-only egress
* Restrict Redis access
* Cross-namespace egress (TCP/80)
* Different sources by port
* Internal-only ingress
* Allow Only frontend → backend (TCP/80)
* bidirectionally-netpol
* network-port

---

## 📝 **ConfigMaps & External Config**

* ConfigMap as Environment Variables
* ConfigMap as Files (NGINX html)
* ConfigMap key → env var (logs verification)
* Create ConfigMap + Fix Nginx Deployment
* Externalize config: ConfigMap + Secret → env
* Mount config files + readiness gating
* cm-nginx-deployment
* cm-logs-verification

---

## 🕒 **Jobs & CronJobs**

* CronJob for Data Pipeline
* CronJob for Database Backup
* CronJob Challenge
* Delta-Ray Diagnostic CronJob
* Finance Team Backup CronJob
* Kubernetes Job with custom parallelism

---

## 📦 **Pods, Probes & Containers**

* Pod Creation + Status Script
* Pod with exec readiness-probe
* Pod with two containers + fsGroup
* Readiness & Liveness on Deployment
* Sidecar Container for Logging
* Pod & Container SecurityContext (Non-root + ReadOnlyRootFS)

---

## 🗃️ **Storage: PV & PVC**

* PV + PVC + Deployment
* ResourceQuota + storage resource checks

---

## 🧭 **Namespace & Workload Movement**

* Migrate a single Pod across namespaces (Prime → Mars)

---

## 🛠️ **API Versions, Debugging & Fixing Manifests**

* Fix API Deprecation Issues
* Fix API Deprecation using `kubectl convert`
* Fix Deployment, Ingress, and Quota issues
* Debug & validate Ingress paths in multi-service app

---

# 🎯 Why This Collection Matters

✔ More complete than most CKAD prep courses

✔ Covers *both* creation & debugging tasks (critical for CKAD)

✔ Includes real-world patterns: canary, blue/green, sidecars, quotas, DNS, PV/PVC

✔ 100% hands-on — no theory only

✔ Perfect for CKAD, real-world Kubernetes, or job interviews

---

# 🚀 Start Practicing

👉 **Your KillerCoda Lab Environment:**
[https://killercoda.com/omkar-shelke25](https://killercoda.com/omkar-shelke25)

> All scenarios launch instantly with a browser terminal — no cluster required.


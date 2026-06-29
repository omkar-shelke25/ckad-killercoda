# 🎉 Completed

You created an internal ClusterIP Service with a port redirect and verified it end-to-end.

## What You Built

```
Namespace: pluto
├── Pod: project-plt-6cc-api
│   ├── image: nginx:1.17.3-alpine
│   └── label: project=plt-6cc-api
└── Service: project-plt-6cc-svc
    ├── type: ClusterIP
    ├── port: 3333
    ├── targetPort: 80
    └── selector: project=plt-6cc-api
```

## What You Accomplished

- ✅ Pod `project-plt-6cc-api` running nginx:1.17.3-alpine with correct label
- ✅ ClusterIP Service `project-plt-6cc-svc` mapping 3333 → 80/TCP
- ✅ HTTP response saved to `/opt/course/10/service_test.html`
- ✅ Nginx access logs saved to `/opt/course/10/service_test.log`

> 💡 `port` is what clients connect to on the Service. `targetPort` is what the container listens on. These two do not need to match — that's the port redirect.

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/ClusterIP-Service-Artifacts)**

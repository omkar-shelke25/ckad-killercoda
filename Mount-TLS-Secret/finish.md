# 🎉 Done!

You created a **TLS Secret** and mounted it into a Pod in the `security` namespace.

## You accomplished
- ✅ Secret **tls-secret** of type `kubernetes.io/tls` from `task4.crt` and `task4.key`
- ✅ Pod **secure-pod** using **redis:8.0.2**
- ✅ Mounted Secret at **/etc/tls** and verified `tls.crt` & `tls.key` exist

> Tip: For TLS Secrets, use `kubectl create secret tls ...` which enforces key names `tls.crt` and `tls.key`, and sets type `kubernetes.io/tls`.

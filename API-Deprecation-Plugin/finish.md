## Completed

You successfully:
- Identified the deprecated API version in the manifest (`apps/v1beta1`)
- Converted it to `apps/v1` using `kubectl-convert`, which also added the required `selector` field and dropped the removed `rollbackTo` field automatically
- Overwrote the manifest file in place at `/ancient-tiger/app.yaml`
- Deployed the application to the **viper** namespace
- Verified all 3 Pods are running

### CKAD Exam Tips
- Practice spotting and fixing deprecated APIs quickly
- Know how to install `kubectl-convert` — it's often not preinstalled
- Remember apps/v1 requires a `selector`, and that old fields can silently break `kubectl apply` if left behind

---

## 🐛 Found an Issue?

This scenario is open source! If something is broken or unclear, please open an issue or PR:

👉 **[github.com/omkar-shelke25/ckad-killercoda](https://github.com/omkar-shelke25/ckad-killercoda/tree/main/API-Deprecation-Plugin)**

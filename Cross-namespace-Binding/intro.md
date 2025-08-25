# 📜 RBAC — Read Pod Logs Only (CKAD-style)

You must allow a **ServiceAccount in `default`** to **view logs** of Pods in **`app-prod`**, and **nothing else**.

- 🎯 Scope: **subresource** `pods/log`
- 🧭 Binding: **cross-namespace** (`default` → `app-prod`)
- 🧪 Verification: strict checks to ensure **only** `pods/log` is allowed

> The setup ensures the target namespace `app-prod` exists so you can focus purely on RBAC and subresources.

Click **Start Scenario** to initialize, then open the task.

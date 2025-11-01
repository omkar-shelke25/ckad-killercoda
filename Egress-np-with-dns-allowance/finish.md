### ✅ **Completed: Egress NetworkPolicy with DNS Exception**

### 🧱 **NetworkPolicy: `np1` (Namespace: `venus`)**

* 🎯 **Pod Selector:** `app=frontend`
* 🔐 **Policy Type:** `Egress`
* 🚦 **Allowed Egress Traffic:**

  * 🔸 **TCP/2222 →** Pods with `app=api`
  * 🌐 **DNS:** UDP/53 and TCP/53

---

### 🧪 **Tests**

| Test Command                                    | Expected Result  | Status |
| ----------------------------------------------- | ---------------- | :----: |
| `nslookup kubernetes.default.svc.cluster.local` | DNS works        |    ✅   |
| `wget http://api:2222`                          | API reachable    |    ✅   |
| `wget www.google.com`                           | External blocked |   🔒   |

### 🌐 **Network Flow Diagram**

```text
               ┌─────────────────────┐
               │     frontend pod     │
               │    (app=frontend)    │
               └──────────┬───────────┘
                          │
       ┌──────────────────┼──────────────────┐
       │                  │                  │
       │                  │                  │
   🌐 DNS 53          🔸 TCP 2222         🚫 Other Traffic
       │                  │                  │
┌───────────────┐   ┌──────────────┐   ┌──────────────────┐
│ kube-dns      │   │  api pods    │   │  External sites  │
│ CoreDNS (53)  │   │ (app=api)    │   │  (e.g., Google)  │
└───────────────┘   └──────────────┘   └──────────────────┘
       ✅                 ✅                   ❌
```


💡 *Great job — you’ve securely locked down egress while preserving necessary functionality!* 🚀



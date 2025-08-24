
## 🔹 NetworkPolicy Ingress/Egress Behavior Table

| **Case**                                    | **policyTypes contains**       | **Rules defined**           | **Behavior**                                                        |
| ------------------------------------------- | ------------------------------ | --------------------------- | ------------------------------------------------------------------- |
| **1. Ingress only, no rules**               | `Ingress`                      | `ingress: []` or omitted    | **All ingress denied** (pods cannot receive any traffic)            |
| **2. Ingress only, allow rules**            | `Ingress`                      | `ingress:` with rules       | **Ingress restricted to matching rules** (all other ingress denied) |
| **3. No Ingress at all**                    | *Ingress not in `policyTypes`* | N/A                         | **All ingress allowed** (default behavior, no isolation)            |
| **4. Egress only, no rules**                | `Egress`                       | `egress: []` or omitted     | **All egress denied** (pods cannot send traffic)                    |
| **5. Egress only, allow rules**             | `Egress`                       | `egress:` with rules        | **Egress restricted to matching rules** (all other egress denied)   |
| **6. No Egress at all**                     | *Egress not in `policyTypes`*  | N/A                         | **All egress allowed** (default behavior, no isolation)             |
| **7. Ingress + Egress, no rules**           | `Ingress, Egress`              | both omitted or `[]`        | **All ingress denied + all egress denied**                          |
| **8. Ingress + Egress, rules only for one** | `Ingress, Egress`              | e.g. only `egress:` defined | **Ingress denied (since listed but no rules) + Egress restricted**  |

---

### ✅ Summary (easy way to remember)

* If a direction (`Ingress` or `Egress`) is **not listed in `policyTypes` → all traffic in that direction is ALLOWED**.
* If it **is listed but has no rules → all traffic in that direction is DENIED**.
* If it **is listed with rules → only traffic matching rules is ALLOWED**, rest is DENIED.


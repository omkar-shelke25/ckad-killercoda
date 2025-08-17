# Database Credentials Security Challenge

## **Question (Weightage: 7)**

A Deployment named `db-client` exists in the `banking` namespace. It currently uses hardcoded environment variables for database credentials.

### **Task:**

**Create a Secret named `db-secret` in the `banking` namespace with:**
- DB_USER=bankadmin
- DB_PASS=securePass123

**Update the `db-client` Deployment so that the environment variables `DB_USER` and `DB_PASS` are loaded from the Secret instead of plain values.**

**Ensure the updated Pods are running with the new configuration.**

---

## **Current Environment Assessment**

First, check the current insecure configuration:

```bash
# Check existing deployment
kubectl get deployment db-client -n banking

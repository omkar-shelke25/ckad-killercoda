# ✅ Completed

- Created a **NetworkPolicy `np1`** in namespace **venus**:
  - Matches pods: `app=frontend`
  - **policyTypes: [Egress]**
  - Allows egress **TCP/2222** to pods `app=api`
  - Allows DNS **UDP/53** and **TCP/53**

**Tests**
- `nslookup kubernetes.default.svc.cluster.local` from a frontend pod → ✅
- `wget http://api:2222` from a frontend pod → ✅

Great job locking down egress while preserving DNS!

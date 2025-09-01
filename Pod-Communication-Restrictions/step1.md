# CKAD: Restrict Pod Communication with Existing NetworkPolicy

In namespace **`ckad00018`**, three Pods exist:

- **web** (should be labeled `app=web`)  
- **db** (should be labeled `app=db`)  
- **ckad00018-newpod** (should be labeled `app=newpod`)  

There is already a **NetworkPolicy** in this namespace.  
You must ensure that **`ckad00018-newpod`** can only send and receive traffic with the Pods `web` and `db`.

### Restrictions
- You are **not allowed** to create, edit, or delete any NetworkPolicy.  
- Only adjust the Pods to comply with the existing NetworkPolicy.  
- The correct policy:  
  - Applies to Pods labeled `app=newpod`  
  - Has both **Ingress** and **Egress** rules  
  - Allows communication only with Pods labeled `app=web` and `app=db`


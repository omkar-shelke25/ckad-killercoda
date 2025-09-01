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


Here’s the **answer** (what the learner should do to fix the intermediate CKAD NetworkPolicy task):

---


### ✅ Step 1: Label the Pods correctly

Since the Pods were created with the wrong labels (`wrong=label`), update them:

```bash
kubectl -n ckad00018 label pod web app=web --overwrite
kubectl -n ckad00018 label pod db app=db --overwrite
kubectl -n ckad00018 label pod ckad00018-newpod app=newpod --overwrite
```

---

### ✅ Step 2: Verify labels

```bash
kubectl -n ckad00018 get pods --show-labels
```

You should see:

```
NAME                 READY   STATUS    RESTARTS   AGE   LABELS
web                  1/1     Running   0          5m    app=web
db                   1/1     Running   0          5m    app=db
ckad00018-newpod     1/1     Running   0          5m    app=newpod
```

---

### ✅ Step 3: Inspect the NetworkPolicy

Check that the policy already matches the requirement:

```bash
kubectl -n ckad00018 describe netpol np-ckad00018
```

You should see:

* **PodSelector: app=newpod**
* **Ingress from:** Pods with labels `app=web` and `app=db`
* **Egress to:** Pods with labels `app=web` and `app=db`
* **PolicyTypes:** Ingress, Egress

---

✅ **Final result:**

* Pod `ckad00018-newpod` is isolated and can only send/receive traffic to/from Pods `web` and `db`, because the labels now align with the pre-existing NetworkPolicy.



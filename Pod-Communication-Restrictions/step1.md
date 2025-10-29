📘 [Network Policies | Kubernetes Docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/)



### 🧩 CKAD: Restrict Pod Communication Using Existing NetworkPolicies

In the namespace `ckad25`, ensure that the Pod named `ckad25-newpod` can communicate **only** with Pods labeled `app=web` and `app=db`.

There are existing NetworkPolicies that already control traffic based on Pod labels — **do not create or modify any NetworkPolicy**.

You must update the configuration of `ckad25-newpod` so that it complies with the existing rules and is able to reach only those two Pods.

> Verify connectivity from `ckad25-newpod` using either `wget` or `curl`, for example:

---

#### ✅ Solution (expand to view)

<details>
<summary>Show Solution</summary>

The existing NetworkPolicies allow communication between Pods with labels `app=web`, `app=db`, and `app=newpod`. 

To enable `ckad25-newpod` to communicate with `web` and `db`, you must label it with `app=newpod`:

```bash
kubectl label pod ckad25-newpod app=newpod -n ckad25
```

**Verification:**

Test connectivity from `ckad25-newpod` to `web`:
```bash
kubectl exec -n ckad25 ckad25-newpod -- wget -qO- --timeout=2 web
```

Test connectivity from `ckad25-newpod` to `db`:
```bash
kubectl exec -n ckad25 ckad25-newpod -- wget -qO- --timeout=2 db:5432
```

Both should succeed (or show connection attempts), indicating the NetworkPolicy allows the communication.

</details>

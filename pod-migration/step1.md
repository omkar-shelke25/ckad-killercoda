# 🚀 Pod Migration Challenge

The prime namespace has six Pods already running from an earlier deployment rush. Each Pod runs a slightly different container name. 

Last night, the lead manager audited workloads and noticed that the 🔴 **mars-container** container does not belong to prime and should be running only in the mars namespace.

You have been asked to migrate only that Pod into mars without disturbing the other five Pods that are correct in prime.


## **Solution**

Try to solve this yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary
                                 
### Export current manifest, change namespace to mars, re-apply:
```bash
kubectl -n prime get pod web-app-04 -o yaml > /tmp/p.yaml
```
### edit: metadata.namespace: mars
### (keep the same name web-app-04)
```bash
kubectl delete pod web-app-04 -n prime
kubectl apply -f /tmp/p.yaml
```

</details>

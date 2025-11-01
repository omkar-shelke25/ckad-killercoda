# CKAD: Egress NetworkPolicy with DNS allowance

In Namespace `venus` you'll find two Deployments named api and frontend. 

Both Deployments are exposed inside the cluster using Services. 

Create a NetworkPolicy named `np1` which restricts outgoing tcp connections from Deployment `frontend` and only allows those going to Deployment `api`. 

Make sure the NetworkPolicy still allows outgoing traffic on UDP/TCP ports `53` for DNS resolution.

> Test using: `wget www.google.com` and `wget api:2222` from a Pod in the **frontend** Deployment.

> `wget www.google.com` ⇒ **failed**

> `wget api:2222` ⇒ **worked**



## ✅ Try it yourself first!

<details><summary>Solution</summary>
  
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: venus
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 2222
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```
</details>

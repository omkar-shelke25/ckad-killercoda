# NetworkPolicy: Different Sources by Port

A workload exposes two entry points and needs to enforce **distinct ingress rules** per port:

- Port **80** is for **frontend traffic** only.
- Port **443** is for **admin traffic** only.

Pods are pre-provisioned. Your task is to write a NetworkPolicy that selects the target pod and allows ingress **per-port** from the correct peer labels.

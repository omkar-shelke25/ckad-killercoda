# NetworkPolicy: Internal-Only Ingress

A namespace needs to permit pod-to-pod traffic **only within itself**, and **deny all ingress** originating from other namespaces.

Pods are **pre-provisioned** for you. Your task is to implement a NetworkPolicy that enforces this rule.

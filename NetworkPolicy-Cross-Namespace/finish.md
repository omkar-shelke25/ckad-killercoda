# 🎉 Well done!

You created a precise NetworkPolicy to allow **egress** from the `source-pod` in `netpol-demo9` to the `target-pod` in `external-ns` on **TCP/80**.

## Key Points
- Combine `namespaceSelector` (match the destination namespace) with `podSelector` (match the destination Pods).
- The label `kubernetes.io/metadata.name: <ns>` is a reliable way to match a namespace by name.
- This policy enables a specific egress path without establishing a full default-deny posture. In production, pair with a **default-deny egress** policy for tighter security.



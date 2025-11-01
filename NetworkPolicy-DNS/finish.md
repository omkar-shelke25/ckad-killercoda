# Congratulations!

You enforced a strict default-deny posture for a sensitive Pod while allowing only the minimal egress needed for **DNS**.

## What you accomplished:

✅ Created a NetworkPolicy named `deny-all-except-dns` in `netpol-demo2`  
✅ Targeted only the `isolated` Pod via `podSelector` (`app=isolated`)  
✅ Denied **all ingress** and **all egress** by default  
✅ Allowed **only** DNS egress (UDP/53) to any destination


```text
                   ┌────────────────────────────┐
                   │        isolated Pod        │
                   │       (app=isolated)       │
                   └────────────┬───────────────┘
                                │
                ┌───────────────┼────────────────┐
                │               │                │
           🌐 DNS :53        🚫 Egress        🚫 Ingress
                │               │                │
        ┌────────────────┐      │                │
        │ CoreDNS        │      │                │
        │   UDP port :53 │      │                │
        └────────────────┘      │                │
                ✅             ❌              ❌
```

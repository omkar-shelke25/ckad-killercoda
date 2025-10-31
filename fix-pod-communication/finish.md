# 🎉 NetworkPolicy Lab Complete!

## What You Accomplished

You successfully enabled the **api-check** pod to communicate with **web-server** and **redis-server** by adding the correct label:

```bash
kubectl label pod api-check -n production function=api-check
```

---

## 🔐 How NetworkPolicies Work

### The Setup

```
┌─────────────────────────────────────────────────────┐
│         default-deny-all NetworkPolicy              │
│              (blocks all traffic)                   │
└─────────────────────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
  ┌───────────┐   ┌───────────┐   ┌──────────┐
  │ web-server│   │   redis   │   │api-check │
  │ netpol    │   │ -server   │   │  utils   │
  │           │   │  netpol   │   │ netpol   │
  └───────────┘   └───────────┘   └──────────┘
       │                │               │
       │                │               │
  Allows FROM      Allows FROM     Applies TO
  function=        function=        function=
  api-check        api-check        api-check
```

### Label Matching Flow

1. **utils-network-policy** applies to pods with `function=api-check`
   - Allows **egress** to `apps.io=web-server` and `cache.io=redis-server`
   - Allows **ingress** from those same pods

2. **web-server-netpol** applies to `apps.io=web-server`
   - Allows **ingress** from `function=api-check`
   - Allows **egress** to `function=api-check`

3. **redis-server-netpol** applies to `cache.io=redis-server`
   - Allows **ingress** from `function=api-check`
   - Allows **egress** to `function=api-check`

---

## 🎯 Key Takeaways

### NetworkPolicy Basics

- NetworkPolicies are **whitelist-based** - you explicitly allow traffic
- They use **label selectors** to identify pods
- Both **source** and **destination** policies must allow traffic
- DNS access often needs explicit egress rules

### CKAD Exam Tips

✅ **Always check pod labels** before assuming NetworkPolicy issues
✅ **Use `--show-labels`** to see all labels on a pod
✅ **Use `kubectl describe networkpolicy`** to understand policy rules
✅ **Remember**: You can add labels to existing pods without recreating them
✅ **Test connectivity** with simple commands like `wget`, `curl`, or `nc`

---

## 📚 Useful Commands

```bash
# View all NetworkPolicies in a namespace
kubectl get networkpolicies -n production

# Describe a specific NetworkPolicy
kubectl describe networkpolicy <name> -n production

# View NetworkPolicy in YAML format
kubectl get networkpolicy <name> -n production -o yaml

# Check pod labels
kubectl get pod <pod-name> -n production --show-labels

# Add a label to a pod
kubectl label pod <pod-name> -n production <key>=<value>

# Remove a label from a pod
kubectl label pod <pod-name> -n production <key>-

# Test pod connectivity
kubectl exec -n production <pod> -- wget -qO- --timeout=2 <service>
kubectl exec -n production <pod> -- nc -zv <service> <port>
```

---

## 🚀 Next Steps

Now that you understand how NetworkPolicies use labels:

1. Practice creating NetworkPolicies for different scenarios
2. Experiment with namespace selectors for cross-namespace communication
3. Learn about egress policies for external traffic control
4. Study how to debug NetworkPolicy issues in production

---

**Congratulations on completing this lab!** 🎊

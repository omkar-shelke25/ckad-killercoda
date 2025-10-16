# 🎉 Completed

You successfully configured resource requests and limits for **both** deployments in the **manga** namespace!

| Case                            | What happens                                           | **QoS Class**     |
| ------------------------------- | ------------------------------------------------------ | ----------------- |
| **Only limit set**              | Kubernetes auto-sets `request = limit`.                | 🟢 **Guaranteed** |
| **Only request set**            | No limit; Pod can use more if node has free resources. | 🟡 **Burstable**  |
| **Both set (equal values)**     | Controlled and predictable (request = limit).          | 🟢 **Guaranteed** |
| **Both set (different values)** | Pod guaranteed minimum, can burst up to limit.         | 🟡 **Burstable**  |
| **Neither set**                 | No guarantees or caps; can be evicted first.           | 🔴 **BestEffort** |



> The `set resources` command only works with `controller workloads`, not with single Pods.

Great work! You've mastered configuring resource requests and limits, a critical skill for the CKAD exam and production Kubernetes environments! 🎊

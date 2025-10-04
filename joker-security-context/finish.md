# ✅ Completed

## 🎉 Congratulations!

You successfully configured **SecurityContext** and **Linux Capabilities** for the joker-deployment!

### What You Accomplished:

1. ✓ **Set runAsUser to 3000** - Container runs as non-root user
2. ✓ **Disabled privilege escalation** - Set `allowPrivilegeEscalation: false`
3. ✓ **Added Linux capabilities:**
   - `NET_BIND_SERVICE` - Bind to ports < 1024 without root
   - `NET_RAW` - Use RAW and PACKET sockets
   - `NET_ADMIN` - Perform network administration tasks
4. ✓ **Saved** changes to `/opt/course/20/joker-deployment-new.yaml`
5. ✓ **Applied** the configuration to the running deployment
6. ✓ **Verified** all pods are running with the new security settings

---

## 🔐 Security Concepts Explained

### **SecurityContext**
Controls privilege and access settings for Pods and containers:
- **runAsUser**: Specifies the UID to run the container process
- **runAsGroup**: Specifies the primary GID
- **fsGroup**: Defines ownership for volumes
- **allowPrivilegeEscalation**: Controls if a process can gain more privileges

### **Why Non-Root Matters**
Running as UID 3000 (non-root) provides:
- **Defense in depth** - Container breakout has less impact
- **Reduced attack surface** - Can't access root-only resources
- **Compliance** - Required by many security policies (PCI-DSS, SOC 2)
- **Best practice** - Principle of least privilege

### **Privilege Escalation Prevention**
Setting `allowPrivilegeEscalation: false`:
- Prevents setuid binaries from changing effective user ID
- Blocks gaining capabilities beyond those explicitly granted
- Essential for multi-tenant environments

### **Linux Capabilities**
Fine-grained privileges instead of all-or-nothing root:

| Capability | Purpose | Example Use Case |
|------------|---------|------------------|
| **NET_BIND_SERVICE** | Bind to ports < 1024 | Web servers on port 80/443 |
| **NET_RAW** | Use RAW/PACKET sockets | Packet capture, ping |
| **NET_ADMIN** | Network configuration | VPN, routing, firewall rules |
| **SYS_TIME** | Set system clock | NTP servers |
| **CHOWN** | Change file ownership | File management tools |

---

## 💡 Common CKAD Scenarios

### **Security Context Levels**

```yaml
# Pod-level (applies to all containers)
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: myapp

# Container-level (overrides pod-level)
spec:
  containers:
  - name: app
    image: myapp
    securityContext:
      runAsUser: 3000
      allowPrivilegeEscalation: false
```

### **Complete Security Example**

```yaml
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE
```

### **Pod Security Standards**

Kubernetes defines three security levels:

1. **Privileged** - Unrestricted (default, not recommended)
2. **Baseline** - Minimally restrictive, prevents known privilege escalations
3. **Restricted** - Heavily restricted, current Pod hardening best practices

Your configuration aligns with **Baseline** standards!

---

## 🎯 Key Exam Tips

1. **Remember the syntax**:
   - Capabilities are UPPERCASE: `NET_BIND_SERVICE`, not `net_bind_service`
   - Use `capabilities.add` and `capabilities.drop` arrays

2. **Container vs Pod level**:
   - `runAsUser` can be set at both levels
   - Container-level overrides pod-level
   - Capabilities can ONLY be set at container level

3. **Common mistakes**:
   - Forgetting `allowPrivilegeEscalation: false`
   - Adding capabilities without understanding what they do
   - Not testing if the pod actually starts after changes

4. **Quick verification**:
   ```bash
   kubectl exec <pod> -- id        # Check user ID
   kubectl exec <pod> -- whoami    # Check username
   kubectl describe pod <pod>      # See security context
   ```

---

## 🚀 Next Steps

**Practice these scenarios**:
- Run as non-root with read-only root filesystem
- Drop all capabilities then add only what's needed
- Use Pod Security Admission controller
- Configure AppArmor or SELinux profiles
- Implement network policies alongside security contexts

**Real-world applications**:
- Databases running as specific users
- Web servers binding to port 80 without root
- Monitoring agents needing specific capabilities
- Compliance with CIS Kubernetes Benchmark

Great work! Security context configuration is frequently tested in CKAD and is critical for production Kubernetes security!

# 🔭 Cluster-wide Node Reader (RBAC)

Your monitoring tool needs **read-only access to Node resources** across the cluster.  
You will create a **ServiceAccount**, grant cluster-wide permissions via **ClusterRole & ClusterRoleBinding**, then **assign that SA to a running Deployment**.

> ⏱️ Setup pre-creates the `monitoring` namespace and a simple `node-inspector-ui` Deployment (without a ServiceAccount). You will attach your SA to it.

Click **Start Scenario** to run setup, then open the task.

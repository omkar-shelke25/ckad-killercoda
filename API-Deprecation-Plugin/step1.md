# CKAD: API Deprecation and Deployment

### Reference Docs
- [Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [API Versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning)
- [kubectl-convert Plugin](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-convert-plugin)
- [Install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

---

## Context

Your cluster runs Kubernetes v1.34. A manifest at `/ancient-tiger/app.yaml` was written for an older release, before `apps/v1beta1` was removed in v1.16. It won't apply as-is — the API version doesn't exist anymore, and it also uses a field from that old spec that apps/v1 no longer has.

## Task

1. **Inspect** `/ancient-tiger/app.yaml` and identify what's deprecated.

2. **Fix it** so it's compatible with apps/v1, then **save the fixed manifest back to the same path**, overwriting the original file.
   - Install and use the `kubectl-convert` plugin rather than hand-editing — it updates the `apiVersion`, adds the `selector` field apps/v1 requires, and strips out fields that no longer exist (like `rollbackTo`), all in one step.
   - > **This part matters for verification**: applying a separately-converted copy isn't enough. Verification checks the file at `/ancient-tiger/app.yaml` itself, so make sure that file is the one you overwrite.

3. **Deploy** the fixed manifest into the **viper** namespace (the original manifest points at `anaconda` — you'll need to change that too).

4. **Confirm** all 3 Pods are running in `viper`.

---

## Installing kubectl-convert (Linux)

Follow the official docs: [Install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

> `kubectl-convert` isn't preinstalled in most exam environments. If you're practicing for the CKAD exam, get comfortable installing it from scratch — you may need to.

---

## Solution

Try it yourself first, then check the solution if needed:

<details>
<summary>Click to view Solution</summary>

### Step 1: Inspect the manifest

```bash
cat /ancient-tiger/app.yaml
kubectl api-versions | grep apps
```

You'll see `apiVersion: apps/v1beta1` — not in the list of API versions your cluster actually supports. You'll also notice `spec.rollbackTo`, a field that only existed on the old `apps/v1beta1`/`extensions/v1beta1` DeploymentSpec and was dropped entirely when the API moved to `apps/v1`.

### Step 2: Convert the manifest with kubectl-convert

```bash
kubectl-convert -f /ancient-tiger/app.yaml --output-version apps/v1
```

Run it first without saving, just to see the output. Compare it to the original — notice two things:
- `apiVersion` is now `apps/v1`
- a `selector.matchLabels` block has been added automatically (apps/v1 requires this; earlier versions inferred it from the Pod template labels)
- `rollbackTo` is gone — apps/v1 doesn't have that field, so kubectl-convert just drops it

> This is exactly why the task recommends `kubectl-convert` over hand-editing: if you only changed the `apiVersion` line yourself and left `rollbackTo` in place, `kubectl apply` would reject the manifest with an "unknown field" error once it's apps/v1.

### Step 3: Save the converted output back over the original file

```bash
kubectl-convert -f /ancient-tiger/app.yaml --output-version apps/v1 | \
  sed 's/namespace: anaconda/namespace: viper/g' > /tmp/converted.yaml
mv /tmp/converted.yaml /ancient-tiger/app.yaml
```

This pipes the converted YAML through `sed` to swap the namespace from `anaconda` to `viper`, writes it to a temp file first (so a mid-write failure can't corrupt the original), then moves it over `/ancient-tiger/app.yaml` — overwriting it in place, which is what verification checks.

```bash
# Confirm the file on disk is actually updated
cat /ancient-tiger/app.yaml
```

### Step 4: Apply it

```bash
kubectl apply -f /ancient-tiger/app.yaml
```

### Step 5: Confirm the deployment is healthy

```bash
kubectl get pods -n viper
kubectl get deployment -n viper
kubectl rollout status deployment/web-app -n viper
```

You should see 3 Pods in the `viper` namespace, all `Running` and `Ready`.

</details>

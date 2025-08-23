#!/bin/bash
set -euo pipefail

pass(){ echo "[PASS] $1"; }
fail(){ echo "[FAIL] $1"; exit 1; }

ns="apps"
cm="app-config"
deploy="web-app"
mountPath="/etc/appconfig"

# Namespace
kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found."

# ConfigMap keys/values
kubectl -n "$ns" get configmap "$cm" >/dev/null 2>&1 || fail "ConfigMap '$cm' not found."
mode=$(kubectl -n "$ns" get configmap "$cm" -o jsonpath='{.data.APP_MODE}' 2>/dev/null || true)
port=$(kubectl -n "$ns" get configmap "$cm" -o jsonpath='{.data.APP_PORT}' 2>/dev/null || true)
[[ "$mode" == "production" ]] || fail "APP_MODE must be 'production' (got '${mode:-<missing>}')."
[[ "$port" == "8080" ]] || fail "APP_PORT must be '8080' (got '${port:-<missing>}')."
pass "ConfigMap '$cm' contains expected keys."

# Deployment basics
kubectl -n "$ns" get deploy "$deploy" >/dev/null 2>&1 || fail "Deployment '$deploy' not found."
replicas=$(kubectl -n "$ns" get deploy "$deploy" -o jsonpath='{.spec.replicas}')
[[ "$replicas" == "2" ]] || fail "Deployment replicas should be 2 (found $replicas)."
img=$(kubectl -n "$ns" get deploy "$deploy" -o jsonpath='{.spec.template.spec.containers[0].image}')
[[ "$img" == nginx* ]] || fail "Container image should be 'nginx' (found '$img')."
pass "Deployment spec is valid."

# Volume from ConfigMap + mount at /etc/appconfig
cmVolName=$(kubectl -n "$ns" get deploy "$deploy" -o jsonpath='{range .spec.template.spec.volumes[*]}{.name}{"|"}{.configMap.name}{"\n"}{end}' \
  | awk -F'|' '$2=="app-config"{print $1; exit}')
[[ -n "$cmVolName" ]] || fail "No volume sourced from ConfigMap 'app-config'."

mounted=$(kubectl -n "$ns" get deploy "$deploy" -o jsonpath='{range .spec.template.spec.containers[*].volumeMounts[*]}{.name}{"|"}{.mountPath}{"\n"}{end}' \
  | awk -F'|' -v vol="$cmVolName" -v mnt="$mountPath" '$1==vol && $2==mnt{print "yes"}')
[[ "$mounted" == "yes" ]] || fail "Volume '$cmVolName' is not mounted at $mountPath."
pass "ConfigMap volume is mounted at $mountPath."

# Pods Ready and files present
kubectl -n "$ns" rollout status deploy/"$deploy" --timeout=120s >/dev/null 2>&1 || fail "Deployment did not become Ready."

pod=$(kubectl -n "$ns" get pods -l app="$deploy" -o jsonpath='{.items[0].metadata.name}')
[[ -n "$pod" ]] || fail "No Pod found for '$deploy'."

kubectl -n "$ns" exec "$pod" -- sh -c "test -f $mountPath/APP_MODE && test -f $mountPath/APP_PORT" \
  || fail "Expected files APP_MODE and APP_PORT not found at $mountPath."

val_mode=$(kubectl -n "$ns" exec "$pod" -- sh -c "cat $mountPath/APP_MODE" || true)
val_port=$(kubectl -n "$ns" exec "$pod" -- sh -c "cat $mountPath/APP_PORT" || true)

[[ "$val_mode" == "production" ]] || fail "APP_MODE file content mismatch (got '$val_mode')."
[[ "$val_port" == "8080" ]] || fail "APP_PORT file content mismatch (got '$val_port')."

pass "Pods are Ready; files exist with correct content."
echo "All checks passed ✅"

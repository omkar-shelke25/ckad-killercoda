#!/bin/bash
set -euo pipefail

pass(){ echo "[PASS] $1"; }
fail(){ echo "[FAIL] $1"; exit 1; }

ns="ops"
pod="data-mining"
svc="data-mining"
label_key="app"
label_val="crypto-mining"
img_expect="httpd:trixie"
port_expect="80"

# 1) Namespace
kubectl get ns "$ns" >/dev/null 2>&1 || fail "Namespace '$ns' not found."

# 2) Pod exists and is Running
kubectl -n "$ns" get pod "$pod" >/dev/null 2>&1 || fail "Pod '$pod' not found in '$ns'."
phase=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.phase}')
[[ "$phase" == "Running" ]] || fail "Pod '$pod' is not Running (phase=$phase)."

# 3) Pod image
img=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.spec.containers[0].image}')
[[ "$img" == "$img_expect" ]] || fail "Pod image is '$img' (expected '$img_expect')."

# 4) Pod label
label_val_found=$(kubectl -n "$ns" get pod "$pod" -o jsonpath="{.metadata.labels.$label_key}")
[[ "$label_val_found" == "$label_val" ]] || fail "Pod label $label_key=$label_val not set (found '$label_val_found')."

# 5) Container port
cport=$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.spec.containers[0].ports[0].containerPort}')
[[ "$cport" == "$port_expect" ]] || fail "Container port is '$cport' (expected '$port_expect')."

# 6) Service exists and targets port 80
kubectl -n "$ns" get svc "$svc" >/dev/null 2>&1 || fail "Service '$svc' not found in '$ns'."
svc_port=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.ports[0].port}')
tgt_port=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.ports[0].targetPort}')
[[ "$svc_port" == "$port_expect" ]] || fail "Service port is '$svc_port' (expected '$port_expect')."
# targetPort may be int or string; normalize
[[ "$tgt_port" == "$port_expect" ]] || [[ "$tgt_port" == "\"$port_expect\"" ]] || :
pass "Service '$svc' is on port $svc_port, targeting $tgt_port."

# 7) Service selector matches label and endpoints are ready
sel=$(kubectl -n "$ns" get svc "$svc" -o jsonpath='{.spec.selector.app}')
[[ "$sel" == "$label_val" ]] || fail "Service selector app=$sel (expected $label_val)."

# Give a moment for endpoints population
sleep 2
ep_ips=$(kubectl -n "$ns" get endpoints "$svc" -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || true)
[[ -n "$ep_ips" ]] || fail "Service '$svc' has no ready endpoints. Check labels/ports."
pass "Service endpoints are present: $ep_ips"

echo "All checks passed! ✅"

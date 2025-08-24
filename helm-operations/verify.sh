#!/usr/bin/env bash
set -euo pipefail

NS_SER="sercury"
NS_VEN="venus"
TARGET_VER="21.1.23"

fail(){ echo "❌ $1"; exit 1; }
ok(){ echo "✓ $1"; }

# --- prerequisites ---
command -v helm >/dev/null 2>&1 || fail "Helm v3 not found in PATH"

has_jq=false
if command -v jq >/dev/null 2>&1; then
  has_jq=true
fi

# --- 1) apiv1 deleted in sercury ---
if helm status internal-issue-report-apiv1 -n "$NS_SER" >/dev/null 2>&1; then
  fail "Release 'internal-issue-report-apiv1' still exists in '$NS_SER'"
else
  ok "'internal-issue-report-apiv1' deleted from '$NS_SER'"
fi

# --- helpers for chart/version extraction ---
get_chart_with_jq() {
  # prints the CHART field (e.g., nginx-21.1.23) for the exact-named release in a namespace
  local rel="$1" ns="$2"
  helm list -n "$ns" -o json \
    | jq -r --arg name "$rel" '.[] | select(.name==$name) | .chart // empty'
}

get_chart_without_jq() {
  # uses table output; CHART is the penultimate column
  # filters to an exact name match to avoid collisions
  local rel="$1" ns="$2"
  helm list -n "$ns" --no-headers \
    | awk -v r="$rel" '$1==r {print $(NF-1)}' | head -n1
}

get_values_replica_with_jq() {
  local rel="$1" ns="$2"
  helm get values "$rel" -n "$ns" -o json \
    | jq -r '.replicaCount // empty'
}

get_values_replica_without_jq() {
  local rel="$1" ns="$2"
  helm get values "$rel" -n "$ns" -o yaml 2>/dev/null \
    | awk '/^replicaCount:/ {print $2; exit}'
}

# --- 2) apiv2 upgraded to EXACT 21.1.23 ---
APIV2_CHART=""
if $has_jq; then
  APIV2_CHART="$(get_chart_with_jq internal-issue-report-apiv2 "$NS_SER")"
else
  APIV2_CHART="$(get_chart_without_jq internal-issue-report-apiv2 "$NS_SER")"
fi

if [[ -z "$APIV2_CHART" ]]; then
  fail "Could not determine chart for 'internal-issue-report-apiv2' in '$NS_SER'"
fi

# Expect "nginx-21.1.23"
if [[ "$APIV2_CHART" == "nginx-$TARGET_VER" ]]; then
  ok "'internal-issue-report-apiv2' is at chart version $TARGET_VER"
else
  fail "'internal-issue-report-apiv2' is not at required chart version $TARGET_VER (found: $APIV2_CHART)"
fi

# --- 3) apache installed with replicaCount=2 via values ---
if ! helm status internal-issue-report-apache -n "$NS_SER" >/dev/null 2>&1; then
  fail "Release 'internal-issue-report-apache' not found in '$NS_SER'"
fi

APACHE_REPL=""
if $has_jq; then
  APACHE_REPL="$(get_values_replica_with_jq internal-issue-report-apache "$NS_SER")"
else
  APACHE_REPL="$(get_values_replica_without_jq internal-issue-report-apache "$NS_SER")"
fi

if [[ "$APACHE_REPL" == "2" ]]; then
  ok "'internal-issue-report-apache' has replicaCount=2 via values"
else
  fail "'internal-issue-report-apache' does not have replicaCount=2 via values (found: ${APACHE_REPL:-unset})"
fi

# --- 4) vulnerabilities uninstalled from venus ---
if helm status vulnerabilities -n "$NS_VEN" >/dev/null 2>&1; then
  fail "Release 'vulnerabilities' still exists in '$NS_VEN'"
else
  ok "'vulnerabilities' removed from '$NS_VEN'"
fi

echo "✅ All checks passed."

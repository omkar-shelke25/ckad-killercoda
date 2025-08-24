#!/usr/bin/env bash
set -euo pipefail

NS_SER="sercury"
NS_VEN="venus"
TARGET_VER="21.1.23"

fail(){ echo "❌ $1"; exit 1; }
ok(){ echo "✓ $1"; }

command -v helm >/dev/null 2>&1 || fail "Helm not found in PATH"

# 1) apiv1 deleted in sercury
if helm status internal-issue-report-apiv1 -n "$NS_SER" >/dev/null 2>&1; then
  fail "Release 'internal-issue-report-apiv1' still exists in '$NS_SER'"
else
  ok "'internal-issue-report-apiv1' deleted from '$NS_SER'"
fi

# 2) apiv2 upgraded to EXACT bitnami/nginx 21.1.23
if ! helm status internal-issue-report-apiv2 -n "$NS_SER" >/dev/null 2>&1; then
  fail "Release 'internal-issue-report-apiv2' not found in '$NS_SER'"
fi
APIV2_CHART="$(helm list -n "$NS_SER" -o json | grep -A2 internal-issue-report-apiv2 | grep '"chart"' | awk -F'":' '{print $2}' | tr -d '," ')"
# Expected like: nginx-21.1.23
if echo "$APIV2_CHART" | grep -q "nginx-$TARGET_VER"; then
  ok "'internal-issue-report-apiv2' is at chart version $TARGET_VER"
else
  fail "'internal-issue-report-apiv2' is not at required chart version $TARGET_VER (found: $APIV2_CHART)"
fi

# 3) apache installed with replicaCount=2
if ! helm status internal-issue-report-apache -n "$NS_SER" >/dev/null 2>&1; then
  fail "Release 'internal-issue-report-apache' not found in '$NS_SER'"
fi
APACHE_REPL="$(helm get values internal-issue-report-apache -n "$NS_SER" -o yaml | awk '/^replicaCount:/{print $2}')"
if [[ "$APACHE_REPL" == "2" ]]; then
  ok "'internal-issue-report-apache' has replicaCount=2 via values"
else
  fail "'internal-issue-report-apache' does not have replicaCount=2 via values (found: ${APACHE_REPL:-unset})"
fi

# 4) vulnerabilities uninstalled from venus
if helm status vulnerabilities -n "$NS_VEN" >/dev/null 2>&1; then
  fail "Release 'vulnerabilities' still exists in '$NS_VEN'"
else
  ok "'vulnerabilities' removed from '$NS_VEN'"
fi

echo "✅ All checks passed."

#!/usr/bin/env bash
set -euo pipefail

NS_SER="sercury"
NS_VEN="venus"

echo "==> Creating namespaces"
kubectl create namespace "$NS_SER" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace "$NS_VEN" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "==> Ensuring Helm v3 is available"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "==> Adding Bitnami repo"
helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true

APIV1_VER="18.2.5"
APIV2_VER="18.2.6"

echo "==> Seeding releases in '$NS_SER' (no --wait for speed)"
# 1) apiv1 at 18.2.5 (to be deleted)
if ! helm status internal-issue-report-apiv1 -n "$NS_SER" >/dev/null 2>&1; then
  echo " -> Installing internal-issue-report-apiv1 (bitnami/nginx $APIV1_VER)"
  helm install internal-issue-report-apiv1 bitnami/nginx \
    -n "$NS_SER" --version "$APIV1_VER" >/dev/null 2>&1 || true
fi

# 2) apiv2 at 18.2.6 (to be upgraded to 21.1.23)
if ! helm status internal-issue-report-apiv2 -n "$NS_SER" >/dev/null 2>&1; then
  echo " -> Installing internal-issue-report-apiv2 (bitnami/nginx $APIV2_VER)"
  helm install internal-issue-report-apiv2 bitnami/nginx \
    -n "$NS_SER" --version "$APIV2_VER" >/dev/null 2>&1 || true
fi

# 3) Do NOT precreate apache; learner will install with --set replicaCount=2

echo "==> Seeding flagged release in '$NS_VEN'"
if ! helm status vulnerabilities -n "$NS_VEN" >/dev/null 2>&1; then
  helm install vulnerabilities bitnami/nginx -n "$NS_VEN" >/dev/null 2>&1 || true
fi

echo "==> Seed complete. Current releases:"
helm ls -A -a || true

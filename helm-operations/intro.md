# Helm — Production Triage 

You’re on call for the `sercury` namespace. Complete the tasks quickly and precisely.

**Preloaded environment**
- `sercury`:
  - `internal-issue-report-apiv1` → bitnami/nginx **18.2.5** (remove this)
  - `internal-issue-report-apiv2` → bitnami/nginx **18.2.6** (upgrade this)
- `venus`:
  - `vulnerabilities` → flagged release (remove it)

> You will delete an old release, perform an **exact** chart upgrade, install a chart with **values**, and clean up a suspicious release in another namespace. Use `helm ls -A -a` to explore.

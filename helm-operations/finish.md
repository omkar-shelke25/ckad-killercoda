# 🎉 Great Job!

You completed the Helm triage:

- ✅ Deleted `internal-issue-report-apiv1` from `sercury`
- ✅ Upgraded `internal-issue-report-apiv2` to **bitnami/nginx 21.1.23**
- ✅ Installed `internal-issue-report-apache` from `bitnami/apache` with **replicaCount=2** via values
- ✅ Removed the suspicious `vulnerabilities` release from `venus`

**Key CKAD takeaways**
- Be **namespace-precise** with `-n <ns>` and use `helm ls` to scope your actions.
- For **exact** upgrades, pair `helm upgrade` with `--version`.
- Prefer `--set` values over manifest edits for app parameters like replicas.
- Cross-namespace hygiene matters: always check `helm ls -A -a`.

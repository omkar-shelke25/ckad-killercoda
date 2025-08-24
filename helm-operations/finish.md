# 🎉 Great Job!

You completed the on-call Helm tasks:

- ✅ Deleted `internal-issue-report-apiv1` from `sercury`
- ✅ Upgraded `internal-issue-report-apiv2` to **bitnami/nginx 21.1.23**
- ✅ Installed `internal-issue-report-apache` from `bitnami/apache` with **replicaCount=2** via values
- ✅ Removed the flagged `vulnerabilities` release from `venus`

**CKAD Takeaways**
- Be **namespace-precise** with `-n <ns>` and use `helm ls` to scope actions.
- Use `helm upgrade --version` for **exact** chart versions.
- Prefer `--set` values for runtime config like replica counts.
- Cross-namespace hygiene: `helm ls -A -a` helps uncover unexpected releases.

# Contributing to CKAD Killercoda Scenarios

Thank you for taking the time to contribute! 🙌  
This project is open source and welcomes improvements of any kind.

---

## 🐛 Reporting a Bug

1. Open an [Issue](https://github.com/omkar-shelke25/ckad-killercoda/issues/new).
2. Use the title format: `[scenario-name] Short description of the problem`  
   e.g. `[monkey.d.luffy-rbac] verify.sh fails even after correct RBAC setup`
3. Include:
   - Which **step** failed
   - The **exact error message** you saw
   - What you tried

---

## 💡 Suggesting an Improvement

Open an Issue with the label `enhancement`. Describe what you'd change and why.

---

## 📝 Fixing an Existing Scenario

1. Fork the repo and create a branch:
   ```bash
   git checkout -b fix/monkey-d-luffy-rbac-verify
   ```
2. Make your changes.
3. Test them — see [Testing Locally](#testing-locally) below.
4. Open a Pull Request against `main` with a clear description of what you changed and why.

---

## ➕ Adding a New Scenario

Each scenario lives in its own folder at the repo root. Follow this structure:

```
your-scenario-name/
├── index.json      # Killercoda metadata (title, steps, backend image)
├── intro.md        # Shown before the student clicks Start
├── step1.md        # Task description (add step2.md etc. for multi-step)
├── finish.md       # Completion page — include the GitHub link for issues
├── setup.sh        # Runs automatically to prepare the lab environment
└── verify.sh       # Runs when the student clicks Check
```

### Checklist before opening a PR for a new scenario

- [ ] Folder name uses lowercase and hyphens (e.g. `pod-security-context`)
- [ ] `index.json` has a clear `title` and `description`
- [ ] `setup.sh` is idempotent — running it twice does not break the lab
- [ ] `setup.sh` does **not** use `set -euo pipefail` at the top level (a single transient kubectl warning should not abort setup)
- [ ] `verify.sh` uses `set -euo pipefail` and exits non-zero on failure
- [ ] Container images are pulled from **Docker Hub** (not ECR or other registries that may be rate-limited on Killercoda)
- [ ] `finish.md` includes the GitHub link for raising issues
- [ ] The scenario has been tested end-to-end on a Killercoda `kubernetes-kubeadm-2nodes` environment

---

## 🧪 Testing Locally

You can't fully replicate Killercoda locally, but you can validate the shell scripts:

```bash
# Lint with shellcheck (install via apt/brew)
shellcheck setup.sh
shellcheck verify.sh
```

For end-to-end testing, create a free Killercoda account and use the
[Killercoda Creator](https://killercoda.com/creator) to point at your fork.

---

## 📐 Style Guide

- Markdown files: use sentence case for headings, keep lines under 120 chars
- Shell scripts: 2-space indent, double-quote all variables, add a comment for non-obvious steps
- Kubernetes resource names: lowercase, hyphens only (no dots or underscores)
- Emoji in `.md` files: fine in moderation — one per heading at most

---

## 📄 License

By contributing you agree that your contributions will be licensed under the [MIT License](./LICENSE).

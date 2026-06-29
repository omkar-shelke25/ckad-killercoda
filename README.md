# 🎯 CKAD Killercoda Scenarios

A collection of hands-on **Killercoda** scenarios to practise for the **Certified Kubernetes Application Developer (CKAD)** exam.

Every scenario drops you into a real Kubernetes cluster with a broken or incomplete setup. Your job is to fix it — just like the real exam.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](./CONTRIBUTING.md)

---

## 📚 Scenarios

| Scenario | Topic | Difficulty | Play |
|---|---|---|---|
| [monkey.d.luffy-rbac](./monkey.d.luffy-rbac/) | RBAC — ServiceAccount, Role, RoleBinding | ⭐ Beginner | [▶ Start](https://killercoda.com/omkar-shelke25/scenario/monkey.d.luffy-rbac) |

> More scenarios coming soon. See [Contributing](CONTRIBUTING.md) if you'd like to add one.

---

## 🗂️ Repo Structure

```bash
ckad-killercoda/
├── monkey.d.luffy-rbac/            # https://killercoda.com/omkar-shelke25/scenario/monkey.d.luffy-rbac
│   ├── index.json                  # Killercoda scenario metadata
│   ├── intro.md                    # Intro page shown before start
│   ├── step1.md                    # Task description
│   ├── finish.md                   # Completion page
│   ├── setup.sh                    # Runs automatically to prepare the lab
│   └── verify.sh                   # Runs when the student clicks "Check"
├── .github/
│   └── workflows/
│       └── shellcheck.yml          # Auto-lints shell scripts on every PR
├── .gitignore
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

Each scenario folder is self-contained and maps directly to a Killercoda scenario.  
> 💡 **URL pattern:** `https://killercoda.com/omkar-shelke25/scenario/<folder-name>`


---

## 🚀 Running a Scenario on Killercoda

1. Go to [killercoda.com](https://killercoda.com) and sign in.
2. Click the scenario link from the table above.
3. Click **Start Scenario** and follow the steps.

No local setup required — Killercoda spins up a real Kubernetes cluster in your browser.

---

## 🤝 Contributing

Contributions are very welcome! Whether it's fixing a bug, improving an explanation, or adding a brand-new scenario — please go ahead.

See **[CONTRIBUTING.md](./CONTRIBUTING.md)** for full guidelines.

Quick version:
1. Fork the repo
2. Create a branch (`git checkout -b fix/scenario-name`)
3. Make your changes
4. Open a Pull Request

---

## 🐛 Found a Bug?

Open an issue and include:
- Which scenario
- Which step failed
- The exact error message you saw

---

## 📄 License

[MIT](./LICENSE) © Omkar Shelke

# ✅ Done!

You granted **read-only access to a single Secret** using `resourceNames` in a Role.

## You accomplished
- ✅ Created Namespace **finance** (precreated by setup)
- ✅ Created Secret **api-key-v2**
- ✅ Created ServiceAccount **specific-secret-reader-sa**
- ✅ Created Role **single-secret-getter-role** with `verbs: [get]`, `resources: ["secrets"]`, and `resourceNames: ["api-key-v2"]`
- ✅ Bound it via RoleBinding **single-secret-getter-binding**
- ✅ Verified: SA can read **only** `secrets/api-key-v2` and no others

> Tip: `resourceNames` is perfect for granting access to **specific** objects without opening access to the entire resource type.


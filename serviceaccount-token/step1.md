# Retrieve the ServiceAccount token and decode it

## Requirements
- Namespace: **`neptune`**
- ServiceAccount: **`neptune-sa-v2`**
- Find the **Secret** associated with this ServiceAccount.
- Extract the **token** (base64 encoded) and Write the decoded token string (exact text, no extra blank lines) to:
  **/opt/course/5/token**

## Try it yourself first!

<details><summary>✅ Solution (expand to view)</summary>

```bash
# 1) Find the Secret linked to the ServiceAccount
kubectl -n neptune get sa neptune-sa-v2 -o yaml | grep -i secrets

# 2) Get the Secret name
SECRET=$(kubectl -n neptune get sa neptune-sa-v2 -o jsonpath='{.secrets[0].name}')

# 3) Extract the base64 token
TOKEN=$(kubectl -n neptune get secret $SECRET -o jsonpath='{.data.token}')

# 4) Decode and save
echo $TOKEN | base64 -d > /opt/course/5/token
```

</details> 

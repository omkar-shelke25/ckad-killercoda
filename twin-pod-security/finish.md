# 🎉 Well Done!

You successfully created a Pod with:

- Two containers (`preproc`, `shipper`)
- Same image
- Different `runAsUser` IDs (1000 and 2000)
- Shared Pod-level `fsGroup`

✅ This pattern is common when multiple processes need **different users** but still require **shared group file permissions**.

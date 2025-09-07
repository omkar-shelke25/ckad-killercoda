## Task: Retrieve and decode the ServiceAccount token

Team Neptune needs the token value stored in the Secret for the ServiceAccount `neptune-sa-v2`.

Steps:
1. Find the Secret `neptune-sa-v2-token` in namespace `neptune`.
2. Extract `.data.token` (it's base64 encoded).
3. Decode the base64 value and write the resulting plain token string to: /opt/course/5/token


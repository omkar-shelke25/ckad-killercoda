## Challenge

Team **Neptune** needs a **Job** template located at `/opt/course/3/job.yaml`.

Requirements:
- The **Job** should:
  - Use image `busybox:1.31.0`
  - Execute the command: `sleep 2 && echo done`
- Namespace: `neptune`
- Name: `neb-new-job`
- Container name: `neb-new-job-container`
- The Job should run **3 completions** and allow **2 runs in parallel**
- Each Pod created should have a label: `id=awesome-job`


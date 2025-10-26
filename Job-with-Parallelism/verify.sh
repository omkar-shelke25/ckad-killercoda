#!/bin/bash

JOB_FILE="/opt/course/3/job.yaml"

# 1. Check if YAML file exists
if [ ! -f "$JOB_FILE" ]; then
  echo "❌ Job manifest $JOB_FILE not found"
  exit 1
fi

# 2. Validate YAML structure (dry-run apply)
kubectl apply --dry-run=client -f $JOB_FILE >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Job manifest $JOB_FILE is not valid"
  exit 1
fi

# 3. Apply manifest (idempotent for verification)
kubectl apply -f $JOB_FILE >/dev/null 2>&1

# 4. Verify Job exists in namespace neptune
kubectl -n neptune get job neb-new-job >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Job neb-new-job not found in namespace neptune"
  exit 1
fi

# 5. Check completions and parallelism
COMPLETIONS=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.completions}')
PARALLELISM=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.parallelism}')

if [ "$COMPLETIONS" != "3" ]; then
  echo "❌ Expected completions=3, found $COMPLETIONS"
  exit 1
fi

if [ "$PARALLELISM" != "2" ]; then
  echo "❌ Expected parallelism=2, found $PARALLELISM"
  exit 1
fi

# 6. Check container name, image, and command
CONTAINER_NAME=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.template.spec.containers[0].name}')
IMAGE=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.template.spec.containers[0].image}')
COMMAND=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.template.spec.containers[0].command}')

if [ "$CONTAINER_NAME" != "neb-new-job-container" ]; then
  echo "❌ Expected container name=neb-new-job-container, found $CONTAINER_NAME"
  exit 1
fi

if [ "$IMAGE" != "public.ecr.aws/docker/library/busybox:stable" ]; then
  echo "❌ Expected image=public.ecr.aws/docker/library/busybox:stable, found $IMAGE"
  exit 1
fi

echo "$COMMAND" | grep -q "sleep 2" || { echo "❌ Command missing 'sleep 2'"; exit 1; }
echo "$COMMAND" | grep -q "echo done" || { echo "❌ Command missing 'echo done'"; exit 1; }

# 7. Check label
LABEL=$(kubectl -n neptune get job neb-new-job -o jsonpath='{.spec.template.metadata.labels.id}')
if [ "$LABEL" != "awesome-job" ]; then
  echo "❌ Expected label id=awesome-job, found $LABEL"
  exit 1
fi

echo "✅ Verification passed! Job manifest and deployment are correct."

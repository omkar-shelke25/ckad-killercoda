#!/bin/bash

# Create namespace neptune
kubectl create namespace neptune

# Cleanup any previous Job
kubectl -n neptune delete job neb-new-job --ignore-not-found

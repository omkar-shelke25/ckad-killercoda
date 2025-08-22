#!/bin/bash

# Check if service exists
if ! kubectl get svc backend-service -n store &>/dev/null; then
    echo "Service 'backend-service' not found in 'store' namespace"
    exit 1
fi

# Check service type
SERVICE_TYPE=$(kubectl get svc backend-service -n store -o jsonpath='{.spec.type}')
if [ "$SERVICE_TYPE" != "ExternalName" ]; then
    echo "Service type is '$SERVICE_TYPE', expected 'ExternalName'"
    exit 1
fi

# Check external name
EXTERNAL_NAME=$(kubectl get svc backend-service -n store -o jsonpath='{.spec.externalName}')
if [ "$EXTERNAL_NAME" != "backend.prod.internal" ]; then
    echo "External name is '$EXTERNAL_NAME', expected 'backend.prod.internal'"
    exit 1
fi

echo "Verification successful! ExternalName service is correctly configured."

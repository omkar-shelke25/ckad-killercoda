#!/bin/bash

# Kubernetes Secrets Challenge Verification Script
# File: verify.sh

echo "=== Kubernetes Secrets Challenge Verification ==="
echo "Checking your solution..."
echo

SCORE=0
TOTAL=7

# Test 1: Check if Secret exists (1 point)
echo "[1/6] Checking if Secret 'db-secret' exists in banking namespace..."
if kubectl get secret db-secret -n banking >/dev/null 2>&1; then
    echo "✅ Secret 'db-secret' found in banking namespace"
    SCORE=$((SCORE + 1))
else
    echo "❌ Secret 'db-secret' not found in banking namespace"
fi
echo

# Test 2: Check Secret has correct keys (1 point)
echo "[2/6] Checking if Secret has required keys..."
HAS_USER=$(kubectl get secret db-secret -n banking -o jsonpath='{.data.DB_USER}' 2>/dev/null)
HAS_PASS=$(kubectl get secret db-secret -n banking -o jsonpath='{.data.DB_PASS}' 2>/dev/null)

if [ -n "$HAS_USER" ] && [ -n "$HAS_PASS" ]; then
    echo "✅ Secret has DB_USER and DB_PASS keys"
    SCORE=$((SCORE + 1))
else
    echo "❌ Secret missing required keys (DB_USER and/or DB_PASS)"
fi
echo

# Test 3: Check Secret values are correct (2 points)
echo "[3/6] Checking Secret values..."
if [ -n "$HAS_USER" ] && [ -n "$HAS_PASS" ]; then
    DB_USER=$(echo "$HAS_USER" | base64 -d 2>/dev/null)
    DB_PASS=$(echo "$HAS_PASS" | base64 -d 2>/dev/null)
    
    if [ "$DB_USER" = "bankadmin" ] && [ "$DB_PASS" = "securePass123" ]; then
        echo "✅ Secret values are correct (DB_USER=bankadmin, DB_PASS=securePass123)"
        SCORE=$((SCORE + 2))
    else
        echo "❌ Secret values incorrect"
        echo "   Expected: DB_USER=bankadmin, DB_PASS=securePass123"
        echo "   Found: DB_USER=$DB_USER, DB_PASS=$DB_PASS"
    fi
else
    echo "❌ Cannot check values - Secret keys not found"
fi
echo

# Test 4: Check Deployment uses secretKeyRef for DB_USER and DB_PASS (2 points)
echo "[4/6] Checking if Deployment uses secretKeyRef..."
DEPLOYMENT=$(kubectl get deployment db-client -n banking -o yaml 2>/dev/null)

if [ -n "$DEPLOYMENT" ]; then
    # Check DB_USER uses secretKeyRef
    USER_SECRET_REF=$(echo "$DEPLOYMENT" | grep -A 10 "name: DB_USER" | grep -A 5 "valueFrom:" | grep -A 3 "secretKeyRef:")
    USER_SECRET_NAME=$(echo "$USER_SECRET_REF" | grep "name: db-secret")
    USER_SECRET_KEY=$(echo "$USER_SECRET_REF" | grep "key: DB_USER")
    
    # Check DB_PASS uses secretKeyRef
    PASS_SECRET_REF=$(echo "$DEPLOYMENT" | grep -A 10 "name: DB_PASS" | grep -A 5 "valueFrom:" | grep -A 3 "secretKeyRef:")
    PASS_SECRET_NAME=$(echo "$PASS_SECRET_REF" | grep "name: db-secret")
    PASS_SECRET_KEY=$(echo "$PASS_SECRET_REF" | grep "key: DB_PASS")
    
    if [ -n "$USER_SECRET_NAME" ] && [ -n "$USER_SECRET_KEY" ] && [ -n "$PASS_SECRET_NAME" ] && [ -n "$PASS_SECRET_KEY" ]; then
        echo "✅ Deployment correctly uses secretKeyRef for DB_USER and DB_PASS"
        SCORE=$((SCORE + 2))
    else
        echo "❌ Deployment not properly configured to use Secret references"
        [ -z "$USER_SECRET_NAME" ] || [ -z "$USER_SECRET_KEY" ] && echo "   DB_USER not properly configured"
        [ -z "$PASS_SECRET_NAME" ] || [ -z "$PASS_SECRET_KEY" ] && echo "   DB_PASS not properly configured"
    fi
else
    echo "❌ Cannot retrieve deployment db-client from banking namespace"
fi
echo

# Test 5: Check no hardcoded credentials remain (1 point)
echo "[5/6] Checking for hardcoded credentials..."
HARDCODED_USER=$(echo "$DEPLOYMENT" | grep -A 2 "name: DB_USER" | grep "value:" | grep -v "sql-service" 2>/dev/null)
HARDCODED_PASS=$(echo "$DEPLOYMENT" | grep -A 2 "name: DB_PASS" | grep "value:" 2>/dev/null)

if [ -z "$HARDCODED_USER" ] && [ -z "$HARDCODED_PASS" ]; then
    echo "✅ No hardcoded credentials found - security improved!"
    SCORE=$((SCORE + 1))
else
    echo "❌ Hardcoded credentials still present"
    [ -n "$HARDCODED_USER" ] && echo "   Found hardcoded DB_USER value"
    [ -n "$HARDCODED_PASS" ] && echo "   Found hardcoded DB_PASS value"
fi
echo

# Test 6: Check DB_HOST is preserved and Pod is running
echo "[6/6] Checking DB_HOST preservation and Pod status..."
DB_HOST_VALUE=$(echo "$DEPLOYMENT" | grep -A 2 "name: DB_HOST" | grep "value:" | awk '{print $2}' | tr -d '"')
POD_STATUS=$(kubectl get pods -n banking -l app=db-client -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

HOST_OK=false
POD_OK=false

if [ "$DB_HOST_VALUE" = "sql-service" ]; then
    echo "✅ DB_HOST environment variable preserved correctly"
    HOST_OK=true
else
    echo "❌ DB_HOST should remain as plain value 'sql-service'"
fi

if [ "$POD_STATUS" = "Running" ]; then
    echo "✅ Pod is running with updated configuration"
    POD_OK=true
else
    echo "❌ Pod not running (Status: $POD_STATUS)"
fi

# Award point only if both conditions met
if [ "$HOST_OK" = true ] && [ "$POD_OK" = true ]; then
    SCORE=$((SCORE + 1))
fi
echo

# Final Results
echo "========================================="
echo "         VERIFICATION RESULTS"
echo "========================================="
echo "Final Score: $SCORE/$TOTAL points"
echo

if [ $SCORE -eq $TOTAL ]; then
    echo "🎉 EXCELLENT! Perfect Score!"
    echo "✅ All security requirements met"
    echo "✅ Challenge completed successfully!"
    echo "🔒 Database credentials are now properly secured!"
elif [ $SCORE -ge 5 ]; then
    echo "✅ Good Job! Most requirements completed"
    echo "📝 Review the failed checks above for improvements"
elif [ $SCORE -ge 3 ]; then
    echo "⚠️  Partial Success - Keep going!"
    echo "📝 Address the failed checks and retry"
else
    echo "❌ Challenge not completed"
    echo "📝 Please review the requirements and try again"
fi

echo
echo "🔍 Debug Commands:"
echo "kubectl get secret db-secret -n banking -o yaml"
echo "kubectl describe deployment db-client -n banking"
echo "kubectl get pods -n banking -o wide"
echo "kubectl logs -n banking -l app=db-client"
echo
echo "💡 Need help? Check the solution in the challenge description!"

# Return appropriate exit code for KillerCoda
if [ $SCORE -eq $TOTAL ]; then
    exit 0
else
    exit 1
fi

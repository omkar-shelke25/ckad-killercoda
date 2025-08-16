---

## step1/verify.sh
```bash
#!/bin/bash

echo "=== CKAD Question Verification (Weightage: 8 points) ==="
TOTAL_POINTS=0
MAX_POINTS=8

# Create namespace if it doesn't exist
if ! kubectl get namespace mars &>/dev/null; then
    kubectl create namespace mars &>/dev/null
    echo "ℹ️  Created mars namespace automatically"
fi

echo ""
echo "📋 Checking Task 1: Deployment Creation (Weightage: 3 points)..."

# Task 1 Verification (3 points)
if ! kubectl get deployment app-server -n mars &>/dev/null; then
    echo "❌ FAILED: Deployment 'app-server' not found in 'mars' namespace"
    echo "   Expected: kubectl create deployment app-server --image=nginx:1.21 --replicas=3 -n mars"
    echo "   Points: 0/3"
else
    REPLICAS=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.replicas}')
    IMAGE=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.template.spec.containers[0].image}')
    
    TASK1_POINTS=0
    
    # Check replica count (1 point)
    if [ "$REPLICAS" = "3" ]; then
        TASK1_POINTS=$((TASK1_POINTS + 1))
        echo "   ✅ Replica count: 3 (1 point)"
    else
        echo "   ❌ Replica count: expected 3, found $REPLICAS (0 points)"
    fi
    
    # Check image (1 point)
    if [ "$IMAGE" = "nginx:1.21" ]; then
        TASK1_POINTS=$((TASK1_POINTS + 1))
        echo "   ✅ Image: nginx:1.21 (1 point)"
    else
        echo "   ❌ Image: expected nginx:1.21, found $IMAGE (0 points)"
    fi
    
    # Check if pods are ready (1 point)
    READY_REPLICAS=$(kubectl get deployment app-server -n mars -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$READY_REPLICAS" = "3" ]; then
        TASK1_POINTS=$((TASK1_POINTS + 1))
        echo "   ✅ Pods ready: 3/3 (1 point)"
    else
        echo "   ❌ Pods ready: $READY_REPLICAS/3 (0 points)"
        echo "   Hint: Wait for pods to start or check deployment status"
    fi
    
    echo "   📊 Task 1 Score: $TASK1_POINTS/3 points"
    TOTAL_POINTS=$((TOTAL_POINTS + TASK1_POINTS))
fi

echo ""
echo "📋 Checking Task 2: QoS Resource Configuration (Weightage: 4 points)..."

# Task 2 Verification (4 points)
if ! kubectl get deployment app-server -n mars &>/dev/null; then
    echo "❌ FAILED: Cannot verify resources - deployment not found"
    echo "   Points: 0/4"
else
    CPU_REQ=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    MEM_REQ=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
    CPU_LIM=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    MEM_LIM=$(kubectl get deployment app-server -n mars -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
    
    TASK2_POINTS=0
    
    # Check CPU request (1 point)
    if [ "$CPU_REQ" = "200m" ]; then
        TASK2_POINTS=$((TASK2_POINTS + 1))
        echo "   ✅ CPU request: 200m (1 point)"
    else
        echo "   ❌ CPU request: expected 200m, found '$CPU_REQ' (0 points)"
    fi
    
    # Check memory request (1 point)
    if [ "$MEM_REQ" = "128Mi" ]; then
        TASK2_POINTS=$((TASK2_POINTS + 1))
        echo "   ✅ Memory request: 128Mi (1 point)"
    else
        echo "   ❌ Memory request: expected 128Mi, found '$MEM_REQ' (0 points)"
    fi
    
    # Check CPU limit (1 point)
    if [ "$CPU_LIM" = "500m" ]; then
        TASK2_POINTS=$((TASK2_POINTS + 1))
        echo "   ✅ CPU limit: 500m (1 point)"
    else
        echo "   ❌ CPU limit: expected 500m, found '$CPU_LIM' (0 points)"
    fi
    
    # Check memory limit (1 point)
    if [ "$MEM_LIM" = "256Mi" ]; then
        TASK2_POINTS=$((TASK2_POINTS + 1))
        echo "   ✅ Memory limit: 256Mi (1 point)"
    else
        echo "   ❌ Memory limit: expected 256Mi, found '$MEM_LIM' (0 points)"
    fi
    
    # Verify QoS class (bonus info)
    if [ $TASK2_POINTS -eq 4 ]; then
        echo "   ⏳ Checking QoS class..."
        sleep 3  # Allow time for pod updates
        BURSTABLE_COUNT=$(kubectl get pods -n mars -o jsonpath='{.items[*].status.qosClass}' | tr ' ' '\n' | grep -c "Burstable" 2>/dev/null || echo "0")
        if [ "$BURSTABLE_COUNT" -gt 0 ]; then
            echo "   ✅ QoS Class: Burstable (confirmed)"
        else
            echo "   ⚠️  QoS Class: Not yet updated (pods may be restarting)"
        fi
    fi
    
    echo "   📊 Task 2 Score: $TASK2_POINTS/4 points"
    TOTAL_POINTS=$((TOTAL_POINTS + TASK2_POINTS))
fi

echo ""
echo "📋 Checking Task 3: Monitoring Script (Weightage: 1 point)..."

# Task 3 Verification (1 point)
TASK3_POINTS=0

if [ ! -f "/opt/mars/qos-check.sh" ]; then
    echo "❌ FAILED: Script /opt/mars/qos-check.sh not found"
    echo "   Expected: Create script at /opt/mars/qos-check.sh"
    echo "   Points: 0/1"
else
    echo "   ✅ Script file exists"
    
    # Test script functionality
    if [ -x "/opt/mars/qos-check.sh" ]; then
        SCRIPT_OUTPUT=$(bash /opt/mars/qos-check.sh 2>/dev/null)
        
        # Check if script produces correct output
        if echo "$SCRIPT_OUTPUT" | grep -q "NAME.*QOS" && echo "$SCRIPT_OUTPUT" | grep -q "Burstable"; then
            TASK3_POINTS=1
            echo "   ✅ Script working correctly"
            echo "   ✅ Output format correct"
            echo "   📊 Task 3 Score: 1/1 points"
        else
            echo "   ❌ Script output format incorrect"
            echo "   Expected format: NAME   QOS"
            echo "   Current output:"
            echo "$SCRIPT_OUTPUT" | head -3
            echo "   📊 Task 3 Score: 0/1 points"
        fi
    else
        echo "   ❌ Script not executable (use chmod +x)"
        echo "   📊 Task 3 Score: 0/1 points"
    fi
fi

TOTAL_POINTS=$((TOTAL_POINTS + TASK3_POINTS))

echo ""
echo "=========================================="
echo "🎯 FINAL SCORE: $TOTAL_POINTS/$MAX_POINTS points"
echo "=========================================="

# Performance evaluation
if [ $TOTAL_POINTS -eq $MAX_POINTS ]; then
    echo "🎉 EXCELLENT! Perfect Score!"
    echo "   ✅ All tasks completed correctly"
    echo "   ✅ Ready for CKAD exam"
    exit 0
elif [ $TOTAL_POINTS -ge 6 ]; then
    echo "✅ GOOD! Strong Performance"
    echo "   ✅ Most objectives achieved"
    echo "   💡 Minor improvements needed"
    exit 0
elif [ $TOTAL_POINTS -ge 4 ]; then
    echo "⚠️  FAIR - Needs Practice"
    echo "   ⚠️  Some core concepts need work"
    echo "   💡 Focus on resource management"
    exit 0
else
    echo "❌ NEEDS IMPROVEMENT"
    echo "   ❌ Review Kubernetes fundamentals"
    echo "   💡 Practice more scenarios"
    exit 1
fi

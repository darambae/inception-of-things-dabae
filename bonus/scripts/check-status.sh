#!/bin/bash

TIMEOUT_SEC=300
INTERVAL=5

echo "Check the readiness of essential GitLab Pods... (Maximum wait time: ${TIMEOUT_SEC} seconds)"

STATEFUL_PODS=("gitlab-postgresql-0" "gitlab-redis-0" "gitlab-gitaly-0")
TOOLBOX_POD=$(kubectl get pods -n gitlab -o custom-columns=NAME:.metadata.name --no-headers | grep toolbox)
if [ -n "$TOOLBOX_POD" ]; then
    STATEFUL_PODS+=("$TOOLBOX_POD")
fi
start_time=$(date +%s)

while true; do
    all_ready=true

    for pod in "${STATEFUL_PODS[@]}"; do
        pod_status=$(kubectl get pod "$pod" -n gitlab -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
        
        if [ "$pod_status" != "true" ]; then
            echo "❌ $pod is not ready"
            all_ready=false
            break
        fi
    done

    if [ "$all_ready" = true ]; then
        total_webservice=$(kubectl get pods -n gitlab -l app=webservice --no-headers 2>/dev/null | wc -l)
        ready_webservice=$(kubectl get pods -n gitlab -l app=webservice -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | grep -o "true" | wc -l)

        if [ "$total_webservice" -eq 0 ] || [ "$total_webservice" -ne "$ready_webservice" ]; then
            echo "❌ webservice pod is not ready (${ready_webservice}/${total_webservice} Ready)"
            all_ready=false
        fi
    fi

    if [ "$all_ready" = true ]; then
        echo "--------------------------------------------------"
        echo "✅ All essential GitLab pods are ready! You can now safely push code to GitLab."
        echo "--------------------------------------------------"
        exit 0
    fi

    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if [ "$elapsed" -ge "$TIMEOUT_SEC" ]; then
        echo "--------------------------------------------------"
        echo "❌ [Timeout] Essential pods did not become ready within the specified time (${TIMEOUT_SEC} seconds)."
        echo "⚠️  Check the cluster resource status with 'kubectl get pods -n gitlab'."
        echo "--------------------------------------------------"
        exit 1
    fi

    echo "🔄 Pods are still initializing. Checking again in ${INTERVAL} seconds... (Elapsed time: ${elapsed} seconds)"
    sleep "$INTERVAL"
done
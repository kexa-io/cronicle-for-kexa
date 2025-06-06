#!/bin/sh

DATE_STAMP=`date "+%Y-%m-%d"`

YOUR_RELEASE_NAME="kexa-helm"



JOB_NAME="kexa-job-run-$DATE_STAMP"

kubectl delete job $JOB_NAME

kubectl create job --from=cronjob/$YOUR_RELEASE_NAME-job $JOB_NAME

# wait for pod to start before following logs

while true; do
    POD_STATUS=$(kubectl get pods --selector=job-name=$JOB_NAME -o jsonpath='{.items[0].status.phase}')
    
    if [ "$POD_STATUS" = "Pending" ] || [ "$POD_STATUS" = "ContainerCreating" ]; then
        echo "Waiting for pod to start..."
        sleep 2
    elif [ "$POD_STATUS" = "Running" ]; then
        echo "Pod is running, following logs..."
        kubectl logs -f job/$JOB_NAME
        break
    elif [ "$POD_STATUS" = "Succeeded" ] || [ "$POD_STATUS" = "Failed" ]; then
        echo "Job completed with status: $POD_STATUS"
        kubectl logs job/$JOB_NAME
        break
    else
        echo "Unknown pod status: $POD_STATUS"
        sleep 2
    fi
done

#kubectl logs -f job/$JOB_NAME


while true; do
    STATUS=$(kubectl get job $JOB_NAME -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
    
    if [ "$STATUS" = "True" ]; then
        echo "Job completed successfully."
        break
    fi
    
    FAILED_STATUS=$(kubectl get job $JOB_NAME -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}')
    if [ "$FAILED_STATUS" = "True" ]; then
        echo "Job failed."
        exit 1
    fi
    
    sleep 5
done

kubectl delete job $JOB_NAME

exit 0
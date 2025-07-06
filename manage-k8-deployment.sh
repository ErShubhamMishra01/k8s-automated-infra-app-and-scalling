#!/bin/bash

ACTION=$1
MASTER_HOST=$2

if [ -z "$MASTER_HOST" ]; then
    echo "Usage: $0 <action> <master-hostname>"
    echo "Actions: deploy, delete, status, kubectl, test-nginx, test-mysql, watch"
    echo "Examples:"
    echo "  $0 deploy ec2-3-236-37-253.compute-1.amazonaws.com"
    echo "  $0 status ec2-3-236-37-253.compute-1.amazonaws.com"
    echo "  $0 test-nginx ec2-3-236-37-253.compute-1.amazonaws.com"
    echo "  $0 test-mysql ec2-3-236-37-253.compute-1.amazonaws.com"
    echo "  $0 watch ec2-3-236-37-253.compute-1.amazonaws.com"
    exit 1
fi

run_ssh() {
    ssh -i "ssh-keys/k8s-ssh-keypair" ubuntu@$MASTER_HOST "$1"
}

case $ACTION in
    deploy)
        echo "Deploying to master: $MASTER_HOST"
        scp -i "ssh-keys/k8s-ssh-keypair" -r deploy-app ubuntu@$MASTER_HOST:~/
        run_ssh "cd ~/deploy-app && kubectl apply -f app-stack.yaml"
        echo "✓ Deployment complete"
        ;;
    delete)
        echo "Deleting from master: $MASTER_HOST"
        run_ssh "cd ~/deploy-app && kubectl delete -f app-stack.yaml"
        echo "✓ Deletion complete"
        ;;
    status)
        echo "Getting status from master: $MASTER_HOST"
        run_ssh "kubectl get deployments,services,pods,scaledobjects"
        ;;
    kubectl)
        KUBECTL_CMD="$3"
        if [ -z "$KUBECTL_CMD" ]; then
            echo "Usage: $0 kubectl <hostname> '<kubectl-command>'"
            exit 1
        fi
        run_ssh "kubectl $KUBECTL_CMD"
        ;;
    test-nginx)
        echo "Testing Nginx scaling on: $MASTER_HOST"
        run_ssh "kubectl delete pod load-test --ignore-not-found=true"
        run_ssh "kubectl run load-test --image=busybox --restart=Never -- /bin/sh -c 'for i in \$(seq 1 1000); do wget -q -O- http://nginx-web-service || true; done'"
        echo "Load test started. Check scaling with: $0 watch $MASTER_HOST"
        ;;
    test-mysql)
        echo "Testing MySQL scaling on: $MASTER_HOST"
        run_ssh "kubectl delete pod mysql-load --ignore-not-found=true"
        run_ssh "kubectl run mysql-load --image=mysql:8.0 --restart=Never -- /bin/sh -c 'for i in \$(seq 1 100); do mysql -h mysql-db-service -u testuser -ptestuser -e \"SELECT COUNT(*) FROM information_schema.tables;\" || true; done'"
        echo "MySQL load test started. Check scaling with: $0 watch $MASTER_HOST"
        ;;
    watch)
        echo "Watching scaling on: $MASTER_HOST"
        run_ssh "kubectl get pods -w"
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Valid actions: deploy, delete, status, kubectl, test-nginx, test-mysql, watch"
        ;;
esac
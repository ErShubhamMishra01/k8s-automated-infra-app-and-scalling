# Kubernetes Cluster with KEDA Auto-scaling

This project sets up a complete Kubernetes cluster on AWS with KEDA auto-scaling for MySQL and Nginx deployments.

## Prerequisites

### AWS User with Required Access
Your AWS user needs the following permissions:
- **EC2**: Full access (create/manage instances, security groups, key pairs)
- **VPC**: Full access (create/manage VPCs, subnets, internet gateways)
- **IAM**: Create roles and instance profiles
- **CloudFormation**: Full access to create/manage stacks

### Required Tools
- AWS CLI configured with your credentials
- Bash shell (Linux/macOS/WSL)

## Part 1: Deploy Infrastructure

### 1. Deploy Cluster
```bash
# Make script executable
chmod +x deploy-cluster.sh

# Deploy cluster (SSH keys are auto-generated)
./deploy-cluster.sh
```

### 2. Verify Deployment
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name test19919191
```

### 3. Infrastructure Components
The deployment creates:
- **VPC** with public subnet
- **Security Group** with required Kubernetes ports
- **Master Node** (t3.medium) with:
  - Kubernetes control plane
  - Calico CNI
  - Helm package manager
  - KEDA auto-scaler
  - Metrics-server (auto-configured)
- **2 Worker Nodes** (t3.medium)

## Part 2: Manage Kubernetes Deployments

### 1. Get Master Node IP
```bash
# Get master node IP from CloudFormation outputs
MASTER_IP=$(aws cloudformation describe-stacks --stack-name test19919191 --query 'Stacks[0].Outputs[?OutputKey==`MasterNodePublicIP`].OutputValue' --output text)
echo $MASTER_IP
```

### 2. Deploy Applications
```bash
# Make script executable
chmod +x manage-k8-deployment.sh

# Deploy MySQL + Nginx with KEDA scaling
./manage-k8-deployment.sh deploy $MASTER_IP

# Check deployment status
./manage-k8-deployment.sh status $MASTER_IP
```

### 3. Application Components
The deployment includes:
- **MySQL Database**:
  - Persistent storage (1Gi)
  - Secret for credentials
  - KEDA scaling: 5% CPU, 10% memory (1-3 replicas)
- **Nginx Web Server**:
  - LoadBalancer service
  - KEDA scaling: 3% CPU, 5% memory (1-10 replicas)

### 4. Test Auto-scaling
```bash
# Test Nginx scaling
./manage-k8-deployment.sh test-nginx $MASTER_IP

# Test MySQL scaling
./manage-k8-deployment.sh test-mysql $MASTER_IP

# Watch scaling in real-time
./manage-k8-deployment.sh watch $MASTER_IP
```

### 5. Management Commands
```bash
# Get all resources
./manage-k8-deployment.sh kubectl $MASTER_IP "get all"

# Check scaling objects
./manage-k8-deployment.sh kubectl $MASTER_IP "get scaledobjects"

# Check metrics
./manage-k8-deployment.sh kubectl $MASTER_IP "top pods"

# Delete deployment
./manage-k8-deployment.sh delete $MASTER_IP
```

## Scaling Thresholds (Very Low for Testing)
- **MySQL**: Scales at 5% CPU or 10% memory usage
- **Nginx**: Scales at 3% CPU or 5% memory usage

## Accessing Applications

### Nginx Web Server
```bash
# Get service details
./manage-k8-deployment.sh kubectl $MASTER_IP "get svc nginx-web-service"

# Access via LoadBalancer IP
curl http://<external-ip>:80
```

### MySQL Database
```bash
# Connect to MySQL
./manage-k8-deployment.sh kubectl $MASTER_IP "run mysql-client --image=mysql:8.0 -it --rm --restart=Never -- mysql -h mysql-db-service -u testuser -p"
# Password: testuser
```

## Troubleshooting

### Debug Commands
```bash
# Check cluster status
./manage-k8-deployment.sh kubectl $MASTER_IP "get nodes"

# Check KEDA pods
./manage-k8-deployment.sh kubectl $MASTER_IP "get pods -n keda"

# Check metrics-server
./manage-k8-deployment.sh kubectl $MASTER_IP "get pods -n kube-system | grep metrics"

# View scaling events
./manage-k8-deployment.sh kubectl $MASTER_IP "describe scaledobject nginx-web-scaler"
```

## Cleanup

### Delete Applications
```bash
./manage-k8-deployment.sh delete $MASTER_IP
```

### Delete Infrastructure
```bash
aws cloudformation delete-stack --stack-name test19919191
```

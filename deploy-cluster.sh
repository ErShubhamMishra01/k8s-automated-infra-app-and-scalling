#!/bin/bash

# Configuration variables
SSH_KEY_NAME="k8s-ssh-keypair"
# STACK_NAME="k8s-cluster"
STACK_NAME="test19919191"

# Deploy Kubernetes cluster with SSH keys
echo "Deploying Kubernetes cluster with inter-node SSH communication..."
echo "Key Name: $SSH_KEY_NAME"
echo "Stack Name: $STACK_NAME"

# Check if SSH keys exist
if [ ! -f "./ssh-keys/${SSH_KEY_NAME}" ] || [ ! -f "./ssh-keys/${SSH_KEY_NAME}.pub" ]; then
    echo "SSH keys not found. Generating them first..."
    cd ssh-keys && ./generate-keys.sh "$SSH_KEY_NAME" && cd ..
fi

# Import public key to AWS (delete if exists first)
echo "Importing public key to AWS..."
aws ec2 delete-key-pair --key-name "$SSH_KEY_NAME" 2>/dev/null || true
aws ec2 import-key-pair --key-name "$SSH_KEY_NAME" --public-key-material fileb://./ssh-keys/${SSH_KEY_NAME}.pub

# Read the keys
PUBLIC_KEY=$(cat ./ssh-keys/${SSH_KEY_NAME}.pub)
PRIVATE_KEY_B64=$(base64 -i ./ssh-keys/${SSH_KEY_NAME} | tr -d '\n')

echo "Deploying CloudFormation stack..."

aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body file://kubernetes-cluster.yaml \
  --parameters \
    ParameterKey=KeyPairName,ParameterValue="$SSH_KEY_NAME" \
    ParameterKey=ClusterPublicKey,ParameterValue="$PUBLIC_KEY" \
    ParameterKey=ClusterPrivateKey,ParameterValue="$PRIVATE_KEY_B64" \
  --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND

if [ $? -eq 0 ]; then
    echo ""
    echo "Stack deployment initiated successfully!"
    echo "Stack name: $STACK_NAME"
    echo ""
    echo "Monitor deployment with:"
    echo "aws cloudformation describe-stacks --stack-name $STACK_NAME"
    
else
    echo "Stack deployment failed!"
    exit 1
fi
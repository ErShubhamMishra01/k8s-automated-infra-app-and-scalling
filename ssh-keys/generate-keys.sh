#!/bin/bash

# Get KEY_PAIR_NAME from parameter or use default
KEY_PAIR_NAME=${1:-"k8s-cluster"}

# Generate SSH key pair for Kubernetes cluster inter-node communication
echo "Generating SSH key pair for Kubernetes cluster..."
echo "Key pair name: $KEY_PAIR_NAME"

# Generate single key pair for cluster communication
ssh-keygen -t rsa -b 2048 -f ${KEY_PAIR_NAME} -N "" -C "${KEY_PAIR_NAME}-cluster-communication"

# Set proper permissions
chmod 600 ${KEY_PAIR_NAME}
chmod 644 ${KEY_PAIR_NAME}.pub

echo ""
echo "SSH key pair generated successfully!"
echo "==================================="
echo "Private key: ./${KEY_PAIR_NAME} (goes to master node)"
echo "Public key: ./${KEY_PAIR_NAME}.pub (goes to all nodes)"
echo ""

# echo "Public key content (for CloudFormation parameter):"
# echo "=================================================="
# cat k8s-cluster-key.pub
# echo ""

# echo "Private key content (for CloudFormation parameter):"
# echo "==================================================="
# cat k8s-cluster-key
# echo ""

echo "Keys are ready for CloudFormation deployment!"
# echo "Master node will get both private and public keys"
# echo "Worker nodes will get only the public key"
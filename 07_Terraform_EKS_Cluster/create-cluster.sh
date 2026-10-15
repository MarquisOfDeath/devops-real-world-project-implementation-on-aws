#!/bin/bash
set -e

echo "==============================="
echo "STEP-1: Create VPC using Terraform"
echo "==============================="
cd Terraform_VPC_forEKS
terraform init 
terraform apply -auto-approve

echo
echo "==============================="
echo "STEP-2: Create EKS Cluster using Terraform"
echo "==============================="
cd ../Terraform_EKS
terraform init 
terraform apply -auto-approve

echo
echo "✅ EKS Cluster and VPC creation completed successfully!"

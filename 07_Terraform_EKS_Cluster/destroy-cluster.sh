#!/bin/bash
set -e

echo "==============================="
echo "STEP-1: Destroy EKS Cluster"
echo "==============================="
cd ../Terraform_EKS
terraform destroy -auto-approve

echo
echo "🧹 Cleaning up local Terraform cache..."
rm -rf .terraform .terraform.lock.hcl

echo
echo "==============================="
echo "STEP-2: Destroy VPC"
echo "==============================="
cd ../0Terraform_VPC_forEKS
terraform destroy -auto-approve

echo
echo "🧹 Cleaning up local Terraform cache..."
rm -rf .terraform .terraform.lock.hcl

echo
echo "✅ EKS Cluster and VPC destroyed and cleaned up successfully!"

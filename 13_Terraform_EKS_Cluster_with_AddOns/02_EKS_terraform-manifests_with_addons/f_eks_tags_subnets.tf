# -------------------------------------------------------------------
# Public Subnet Tags for EKS Load Balancer Support
# -------------------------------------------------------------------

# Allows EKS to automatically discover these subnets to host internet-facing ALBs and NLBs.
resource "aws_ec2_tag" "eks_subnet_tag_public_elb" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.root_mod_public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}


# Use "owned" when your subnets are dedicated exclusively to one single EKS cluster. 
# If you delete that EKS cluster, these subnets should technically be destroyed or left completely empty.

# "shared" is This is the safest and most common choice for enterprise/production environments. 
# Even if you only have one cluster today, you might add a second cluster to the same VPC tomorrow, 
# or you might have databases (like RDS) running in those same subnets.

resource "aws_ec2_tag" "eks_subnet_tag_public_cluster" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.root_mod_public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

# -------------------------------------------------------------------
# Private Subnet Tags for EKS Internal LoadBalancer Support
# -------------------------------------------------------------------

# Allows EKS to automatically discover these subnets to host internal (VPC-only) ALBs and NLBs.
resource "aws_ec2_tag" "eks_subnet_tag_private_elb" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.root_mod_private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Use "owned" when your subnets are dedicated exclusively to one single EKS cluster. 
# If you delete that EKS cluster, these subnets should technically be destroyed or left completely empty.

# "shared" is This is the safest and most common choice for enterprise/production environments. 
# Even if you only have one cluster today, you might add a second cluster to the same VPC tomorrow, 
# or you might have databases (like RDS) running in those same subnets.

resource "aws_ec2_tag" "eks_subnet_tag_private_cluster" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.root_mod_private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "shared"
}

# ------------------------------------------------------------------------------
# IAM Role for EKS Control Plane
# This role is assumed by the EKS service to manage the control plane resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  # Unique name for the control plane IAM role
  name = "${local.name}-eks-cluster-role"

  # Trust policy to allow EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  # Tags applied to this IAM role
  tags = var.tags
}

/*

Think of this code as creating an identity badge for the EKS service. 
By default, AWS services are completely blocked from touching each other's resources. 
This block builds an empty badge, names it, and defines a "trust rule" that allows the Amazon EKS service to wear it.

*/


# ------------------------------------------------------------------------------
# Attach the required policy for EKS to manage cluster control plane
# This is mandatory for all EKS clusters
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

/*


What is it?

This is the core foundation policy for Amazon EKS. 
It grants the EKS Control Plane (which lives in AWS's managed account) permission to reach into your account to create 
and manage the basic components required to run a Kubernetes cluster.

What does it explicitly allow? (Real-World Examples)

• Creating Network Interfaces (ENIs): It allows the control plane to spin up those special cross-account network cards 
directly inside your VPC subnets so it can talk to your worker nodes.

• Managing Auto Scaling Groups: It gives EKS the permission to discover and coordinate with the EC2 instances 
acting as your worker nodes.

• Security Group Rules: It allows EKS to automatically configure security groups so that the control plane 
and data plane can securely communicate without you manually opening ports.

Why is it mandatory?

Without this policy, the EKS Control Plane is completely blind and isolated. 
It won't have permission to create the network bridge into your VPC, meaning your cluster creation will get stuck 
indefinitely and eventually fail.

*/


# ------------------------------------------------------------------------------
# Attach VPC Resource Controller policy
# Required for advanced networking, Fargate, and Karpenter support
# Recommended to include by default for production-grade EKS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

/*

What is it?

This policy allows the EKS control plane to manage specialized networking resources inside your VPC. 
Specifically, it enables a background process called the VPC Resource Controller.

What does it explicitly allow? (Real-World Examples)

• Running Pods on AWS Fargate: If you ever decide to run serverless pods using Fargate alongside your EC2 instances, 
this policy allows EKS to assign private IP addresses directly from your subnets to those Fargate pods.

• Security Groups for Pods (Production Crucial): Normally, all pods on a worker node share the same security group. 
In a production environment, you often want strict isolation 
(e.g., your Payment Pod should have different firewall rules than your Frontend Pod). 
This policy gives EKS the power to hook AWS Security Groups directly to individual Kubernetes pods.

• IP Address Optimization: It helps manage and track the allocation of network interfaces and private IPs 
so your cluster doesn't waste network space.

Why is it mandatory?

While your cluster might technically boot up without it, you will completely break native AWS network features inside Kubernetes. 
For a production-grade cluster, this policy is essential for advanced security auditing, 
network isolation, and serverless scaling.

*/
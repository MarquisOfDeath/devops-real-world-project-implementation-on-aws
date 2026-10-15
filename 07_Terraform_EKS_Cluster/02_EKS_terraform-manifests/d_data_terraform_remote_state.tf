# --------------------------------------------------------------------
# Reference the Remote State from VPC Project
# --------------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "tfstate-bucket-dev01-ap-south-1-p8m28cyh" # Name of the remote S3 bucket where the VPC state is stored
    key    = "eks_cluster/vpc/terraform.tfstate"        # Path to the VPC tfstate file within the bucket
    region = var.aws_region                             # Region where the S3 bucket and DynamoDB table exist
  }
}

# --------------------------------------------------------------------
# Output the VPC ID from the remote VPC state
# --------------------------------------------------------------------
output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.root_mod_vpc_id
}

# --------------------------------------------------------------------
# Output the list of private subnets from the VPC
# --------------------------------------------------------------------
output "private_subnet_ids" {
  value = data.terraform_remote_state.vpc.outputs.root_mod_private_subnet_ids
}


# --------------------------------------------------------------------
# Output the list of public subnets from the VPC
# --------------------------------------------------------------------
output "public_subnet_ids" {
  value = data.terraform_remote_state.vpc.outputs.root_mod_public_subnet_ids
}



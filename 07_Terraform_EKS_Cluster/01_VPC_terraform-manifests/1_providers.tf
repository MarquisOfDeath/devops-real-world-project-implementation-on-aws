# ==============================================================================
# TERRAFORM BLOCK & PROVIDER CONFIGURATION
# ==============================================================================

terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  # Remote backend storing our state file in AWS S3 with native lockfile enabled
  backend "s3" {
    bucket       = "tfstate-bucket-dev01-ap-south-1-p8m28cyh"
    key          = "eks_cluster/vpc/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

# The AWS provider uses the region and tag parameters passed from the root variables
provider "aws" {
  region = var.root_mod_aws_region

  default_tags {
    tags = var.root_mod_tags
  }

    # ----------------------------------------------------------------------------
  # THE GOLD STANDARD FOR PRODUCTION EKS NETWORKING
  # This globally instructs Terraform to drop/ignore all dynamic Kubernetes tags
  # ----------------------------------------------------------------------------
  ignore_tags {
    key_prefixes = [
      "kubernetes.io/cluster/", # Automatically catches ANY cluster name dynamically generated
      "kubernetes.io/role/"     # Automatically catches elb and internal-elb tags safely
    ]
  }
  
}

provider "random" {}
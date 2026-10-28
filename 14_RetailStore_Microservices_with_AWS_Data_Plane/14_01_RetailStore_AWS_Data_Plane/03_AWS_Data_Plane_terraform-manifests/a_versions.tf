terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68"
    }
  }

  # Remote backend storing our state file in AWS S3 with native lockfile enabled
  backend "s3" {
    bucket       = "tfstate-bucket-dev01-ap-south-1-p8m28cyh"
    key          = "eks_cluster/retailstore/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  # AWS region to use for all resources (from variables)
  region = var.aws_region
}


# Secondary provider specifically for Cart's DynamoDB table
provider "aws" {
  alias  = "west2"
  region = "us-west-2"
}
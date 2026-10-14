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
    key          = "vpc_modules/staging/terraform.tfstate"
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
}

provider "random" {}
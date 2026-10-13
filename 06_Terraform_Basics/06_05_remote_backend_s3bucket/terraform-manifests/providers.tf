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
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  # Feeds your global variable directly into the provider default tags
  default_tags {
    tags = var.tags
  }
}

provider "random" {} 
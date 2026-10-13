variable "environment_name" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  #default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy backend (e.g., us-west-2)"
  type        = string
  #default     = "us-east-1"
}

variable "tags" {
  description = "Global tags to apply to all resources"
  type        = map(string)
  default = {
    IAC_tool   = "Terraform"
    ComingFrom = "terraform_aws_providers_block"
  }
}
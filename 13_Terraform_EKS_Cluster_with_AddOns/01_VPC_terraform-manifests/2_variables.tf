# ==============================================================================
# ROOT MODULE VARIABLES DECLARATION
# These variables receive values from terraform.tfvars or CLI flags (-var).
# ==============================================================================

variable "root_mod_aws_region" {
  description = "Target AWS region for infrastructure deployment"
  type        = string
}

variable "root_mod_environment_name" {
  description = "Target deployment environment (e.g., Staging, Production, Dev)"
  type        = string
}

variable "root_mod_vpc_cidr" {
  description = "The overarching IPv4 CIDR block assigned to the VPC"
  type        = string
}

variable "root_mod_subnet_newbits" {
  description = "Number of additional bits to divide the VPC CIDR into subnet blocks"
  type        = number
}

variable "root_mod_tags" {
  description = "Global baseline tags applied across resources via the AWS provider"
  type        = map(string)
  default = {
    IAC_tool   = "Terraform"
    ComingFrom = "Terraform_AWS_providers_block"
  }
}
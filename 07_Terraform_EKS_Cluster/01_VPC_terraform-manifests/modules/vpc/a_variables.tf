# ==============================================================================
# CHILD MODULE INPUT VARIABLES
# These represent inputs that any caller must provide to use this VPC module.
# ==============================================================================

variable "child_mod_aws_region" {
  description = "Region to be associated with resource configuration"
  type        = string
}

variable "child_mod_environment_name" {
  description = "Environment name used in dynamic resource names and Name tags"
  type        = string
}

variable "child_mod_vpc_cidr" {
  description = "Base IPv4 CIDR block for constructing the VPC"
  type        = string
}

variable "child_mod_subnet_newbits" {
  description = "Additional netmask bits added to child_mod_vpc_cidr to carve out subnets"
  type        = number
}

variable "child_mod_tags" {
  description = "Map of tags merged directly into child resource Name tags"
  type        = map(string)
  default     = {}
}
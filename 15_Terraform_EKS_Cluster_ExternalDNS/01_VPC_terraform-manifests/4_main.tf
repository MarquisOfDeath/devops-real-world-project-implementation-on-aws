# ==============================================================================
# CHILD MODULE INVOCATION
# Format: <child_mod_input_name> = var.<root_mod_input_name>
#
# LEFT SIDE  : Declared inside modules/vpc/variables.tf (What child module accepts)
# RIGHT SIDE : Declared inside root variables.tf (Values parent passes down)
# ==============================================================================

module "vpc" {
  source = "./modules/vpc"

  # Forwarding root values down into child input parameters
  child_mod_aws_region       = var.root_mod_aws_region
  child_mod_environment_name = var.root_mod_environment_name
  child_mod_vpc_cidr         = var.root_mod_vpc_cidr
  child_mod_subnet_newbits   = var.root_mod_subnet_newbits

  # Passing specific tags defined for the VPC resources
  child_mod_tags = {
    Environment = "NonProd"
    ManagedBy   = "Terraform"
    Owner       = "MarquisOfDeath"
    Source      = "Terraform_AWS_locals_block"
  }
}
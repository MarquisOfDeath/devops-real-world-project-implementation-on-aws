# ==============================================================================
# ROOT MODULE OUTPUTS
# Exposes values returned from the child module to CLI stdout or state.
# Format: value = module.<MODULE_NAME>.<CHILD_OUTPUT_NAME>
# ==============================================================================

output "root_mod_vpc_id" {
  description = "The unique identifier of the core network VPC"
  value       = module.vpc.child_mod_vpc_id
}

output "root_mod_vpc_cidr_block" {
  description = "The primary CIDR network block bound to the VPC"
  value       = module.vpc.child_mod_vpc_cidr_block
}

output "root_mod_internet_gateway_id" {
  description = "The unique identifier of the attached Edge Internet Gateway"
  value       = module.vpc.child_mod_internet_gateway_id
}

output "root_mod_public_subnet_ids" {
  description = "Mapping of Availability Zones to Public Subnet IDs"
  value       = module.vpc.child_mod_public_subnet_ids
}

output "root_mod_public_subnet_cidrs" {
  description = "Mapping of Availability Zones to Public Subnet CIDR blocks"
  value       = module.vpc.child_mod_public_subnet_cidrs
}

output "root_mod_private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = module.vpc.child_mod_private_subnet_ids
}

output "root_mod_private_subnet_cidrs" {
  description = "List of Private Subnet CIDR blocks"
  value       = module.vpc.child_mod_private_subnet_cidrs
}

output "root_mod_nat_eip_public_ip" {
  description = "The external public Elastic IP bound to the outbound NAT Gateway"
  value       = module.vpc.child_mod_nat_eip_public_ip
}

output "root_mod_nat_gateway_id" {
  description = "The unique identifier token of the single outbound NAT Gateway"
  value       = module.vpc.child_mod_nat_gateway_id
}

output "root_mod_public_route_table_id" {
  description = "The unique identifier of the Public Network Route Table"
  value       = module.vpc.child_mod_public_route_table_id
}

output "root_mod_private_route_table_id" {
  description = "The unique identifier of the Private Network Route Table"
  value       = module.vpc.child_mod_private_route_table_id
}
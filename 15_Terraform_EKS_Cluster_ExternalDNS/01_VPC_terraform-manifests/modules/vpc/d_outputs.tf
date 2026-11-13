# ==============================================================================
# CHILD MODULE OUTPUTS
# These values are made available to any parent module invoking this child.
# ==============================================================================

output "child_mod_vpc_id" {
  description = "The unique identifier of the core network VPC"
  value       = aws_vpc.terraform_vpc.id
}

output "child_mod_vpc_cidr_block" {
  description = "The primary CIDR network block bound to the VPC"
  value       = aws_vpc.terraform_vpc.cidr_block
}

output "child_mod_internet_gateway_id" {
  description = "The unique identifier of the attached Edge Internet Gateway"
  value       = aws_internet_gateway.terraform_igw.id
}

/*

output "child_mod_public_subnet_ids" {
  description = "Mapping of Availability Zones to Public Subnet IDs"
  value       = { for az, subnet in aws_subnet.terraform_public_subnet : az => subnet.id }
}

output "child_mod_public_subnet_cidrs" {
  description = "Mapping of Availability Zones to Public Subnet CIDR blocks"
  value       = { for az, subnet in aws_subnet.terraform_public_subnet : az => subnet.cidr_block }
}

output "child_mod_private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = [for subnet in aws_subnet.terraform_private_subnet : subnet.id]
}

output "child_mod_private_subnet_cidrs" {
  description = "List of Private Subnet CIDR blocks"
  value       = [for subnet in aws_subnet.terraform_private_subnet : subnet.cidr_block]
}

*/

output "child_mod_public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = [for subnet in aws_subnet.terraform_public_subnet : subnet.id]
}

output "child_mod_public_subnet_cidrs" {
  description = "Mapping of Availability Zones to Public Subnet CIDR blocks"
  value       = { for az, subnet in aws_subnet.terraform_public_subnet : az => subnet.cidr_block }
}

output "child_mod_private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = [for subnet in aws_subnet.terraform_private_subnet : subnet.id]
}

output "child_mod_private_subnet_cidrs" {
  description = "Mapping of Availability Zones to Private Subnet CIDR blocks"
  value       = { for az, subnet in aws_subnet.terraform_private_subnet : az => subnet.cidr_block }
}

output "child_mod_nat_eip_public_ip" {
  description = "The static external public Elastic IP bound to the outbound NAT Gateway"
  value       = aws_eip.terraform_nat_eip.public_ip
}

output "child_mod_nat_gateway_id" {
  description = "The unique identifier token of the single outbound NAT Gateway"
  value       = aws_nat_gateway.terraform_nat[local.azs[0]].id
}

output "child_mod_public_route_table_id" {
  description = "The unique identifier of the Public Network Route Table"
  value       = aws_route_table.terraform_public_rt.id
}

output "child_mod_private_route_table_id" {
  description = "The unique identifier of the Private Network Route Table"
  value       = aws_route_table.terraform_private_rt.id
}
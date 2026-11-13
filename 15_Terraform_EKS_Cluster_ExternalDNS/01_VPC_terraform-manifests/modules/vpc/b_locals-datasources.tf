# ==============================================================================
# DATA SOURCES & LOCAL VALUE CALCULATIONS
# ==============================================================================

# Query AWS for all operational Availability Zones in the current provider region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # ----------------------------------------------------------------------------
  # 1. AZ SELECTION (local.azs):
  # data.aws_availability_zones.available.names returns all AZs in the region.
  # slice(list, 0, 3) extracts the first 3 AZs (indexes 0, 1, 2).
  # ----------------------------------------------------------------------------
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # ----------------------------------------------------------------------------
  # 2. PUBLIC SUBNET CIDR CALCULATION (local.public_subnets):
  # cidrsubnet(iprange, newbits, netnum) splits a parent CIDR into smaller subnets.
  # - var.child_mod_vpc_cidr: 10.0.0.0/16
  # - var.child_mod_subnet_newbits: 8 (16 + 8 = /24 subnets)
  # - k: loop index (0, 1, 2)
  #   Round 1 (k=0) -> 10.0.0.0/24
  #   Round 2 (k=1) -> 10.0.1.0/24
  #   Round 3 (k=2) -> 10.0.2.0/24
  # ----------------------------------------------------------------------------
  public_subnets = [
    for k, az in local.azs : cidrsubnet(var.child_mod_vpc_cidr, var.child_mod_subnet_newbits, k)
  ]

  # ----------------------------------------------------------------------------
  # 3. PRIVATE SUBNET CIDR CALCULATION (local.private_subnets):
  # Adding 10 to k skips the first 10 /24 slots, avoiding IP collisions with public subnets.
  #   Round 1 (k=0, netnum=10) -> 10.0.10.0/24
  #   Round 2 (k=1, netnum=11) -> 10.0.11.0/24
  #   Round 3 (k=2, netnum=12) -> 10.0.12.0/24
  # ----------------------------------------------------------------------------
  private_subnets = [
    for k, az in local.azs : cidrsubnet(var.child_mod_vpc_cidr, var.child_mod_subnet_newbits, k + 10)
  ]

  # Standardized reference for tag merging
  global_tags = var.child_mod_tags
}
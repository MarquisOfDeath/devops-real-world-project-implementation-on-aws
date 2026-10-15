# ==============================================================================
# RESOURCE 1: VPC
# The isolated virtual network container
# ==============================================================================
resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.child_mod_vpc_cidr
  enable_dns_hostnames = true
  region               = var.child_mod_aws_region
  enable_dns_support   = true

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-vpc"
  })

  lifecycle {
    prevent_destroy = false
  }
}

# ==============================================================================
# RESOURCE 2: INTERNET GATEWAY (IGW)
# Provides inbound/outbound internet access for public subnets
# ==============================================================================
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-igw"
  })
}

# ==============================================================================
# RESOURCE 3: PUBLIC SUBNETS
# Maps each AZ key to its calculated CIDR block from local.public_subnets
# ==============================================================================
resource "aws_subnet" "terraform_public_subnet" {
  for_each = { for idx, az in local.azs : az => local.public_subnets[idx] }

  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.global_tags, {
    Name        = "corp-${var.child_mod_environment_name}-public-subnet-${each.key}"
    Subnet_Tier = "Public"
  })

  # PRODUCTION LIFECYCLE RULE: Public Load Balancing Discovery
  lifecycle {
    ignore_changes = [
      # Ignores internet-facing ELB routing tags injected by the AWS Load Balancer Controller
      tags["kubernetes.io/role/elb"],
      
      # Ignores dynamic cluster ownership tracking flags mapping back to your EKS name
      tags["kubernetes.io/cluster/retail-dev-marquiseksluster"]
    ]
  }

}

# ==============================================================================
# RESOURCE 4: PRIVATE SUBNETS
# Subnets without direct external access
# ==============================================================================
resource "aws_subnet" "terraform_private_subnet" {
  for_each = { for idx, az in local.azs : az => local.private_subnets[idx] }

  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.global_tags, {
    Name        = "corp-${var.child_mod_environment_name}-private-subnet-${each.key}"
    Subnet_Tier = "Private"
  })

  # PRODUCTION LIFECYCLE RULE: Private/Internal Load Balancing Discovery
  lifecycle {
    ignore_changes = [
      # Ignores internal-only ELB routing tags injected by the AWS Load Balancer Controller
      tags["kubernetes.io/role/internal-elb"],
      
      # Ignores dynamic cluster ownership tracking flags mapping back to your EKS name
      tags["kubernetes.io/cluster/retail-dev-marquiseksluster"]
    ]
  }

}

# ==============================================================================
# RESOURCE 5: ELASTIC IP FOR NAT GATEWAY
# Static IP assigned to the outbound NAT Gateway
# ==============================================================================
resource "aws_eip" "terraform_nat_eip" {
  domain = "vpc"

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-nat-eip"
  })

  depends_on = [aws_internet_gateway.terraform_igw]
}

# ==============================================================================
# RESOURCE 6: NAT GATEWAY
# Hosted inside the 1st public subnet to grant private subnets outbound egress
# ==============================================================================
resource "aws_nat_gateway" "terraform_nat" {
  for_each      = toset([local.azs[0]])
  allocation_id = aws_eip.terraform_nat_eip.id
  subnet_id     = aws_subnet.terraform_public_subnet[each.key].id

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-vpc-nat-gw-${each.key}"
  })

  depends_on = [aws_internet_gateway.terraform_igw]
}

# ==============================================================================
# RESOURCE 7: PUBLIC ROUTE TABLE
# Default route (0.0.0.0/0) targets the Internet Gateway
# ==============================================================================
resource "aws_route_table" "terraform_public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-public-rt"
  })
}

# ==============================================================================
# RESOURCE 8: PUBLIC ROUTE TABLE ASSOCIATIONS
# Binds the public route table to all public subnets
# ==============================================================================
resource "aws_route_table_association" "terraform_public_rt_assoc" {
  for_each       = aws_subnet.terraform_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terraform_public_rt.id
}

# ==============================================================================
# RESOURCE 9: PRIVATE ROUTE TABLE
# Default route (0.0.0.0/0) routes outbound traffic through the single NAT Gateway
# ==============================================================================
resource "aws_route_table" "terraform_private_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat[local.azs[0]].id
  }

  tags = merge(local.global_tags, {
    Name = "corp-${var.child_mod_environment_name}-private-rt"
  })
}

# ==============================================================================
# RESOURCE 10: PRIVATE ROUTE TABLE ASSOCIATIONS
# Binds the private route table to all private subnets
# ==============================================================================
resource "aws_route_table_association" "terraform_private_rt_assoc" {
  for_each       = aws_subnet.terraform_private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terraform_private_rt.id
}
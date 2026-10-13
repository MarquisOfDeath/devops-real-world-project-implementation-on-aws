# Resource-1: VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  region               = var.aws_region
  enable_dns_support   = true
  tags                 = merge(local.global_tags, { Name = "corp-${var.environment_name}-vpc" })
  lifecycle {
    prevent_destroy = false
  }
}

# Resource-2: Internet Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags   = merge(local.global_tags, { Name = "corp-${var.environment_name}-igw" })
}

# Resource-3: Public Subnets
resource "aws_subnet" "terraform_public_subnet" {
  # Inline generation matching AZ string keys to their corresponding computed CIDRs
  for_each = { for idx, az in local.azs : az => local.public_subnets[idx] }

  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.global_tags, {
    Name        = "corp-${var.environment_name}-public-subnet-${each.key}"
    Subnet_Tier = "Public"
  })
}

# Resource-4: Private Subnets
resource "aws_subnet" "terraform_private_subnet" {
  # Inline generation matching AZ string keys to their corresponding computed CIDRs
  for_each = { for idx, az in local.azs : az => local.private_subnets[idx] }

  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.global_tags, {
    Name        = "corp-${var.environment_name}-private-subnet-${each.key}"
    Subnet_Tier = "Private"
  })
}

# Resource-5: Elastic IP for NAT Gateway
resource "aws_eip" "terraform_nat_eip" {
  domain     = "vpc"
  tags       = merge(local.global_tags, { Name = "corp-${var.environment_name}-nat-eip" })
  depends_on = [aws_internet_gateway.terraform_igw]
}

# Resource-6: NAT Gateway
# Creates exactly 1 NAT Gateway hosted inside the 1st public subnet
resource "aws_nat_gateway" "terraform_nat" {
  for_each      = toset([local.azs[0]])
  allocation_id = aws_eip.terraform_nat_eip.id
  subnet_id     = aws_subnet.terraform_public_subnet[each.key].id

  tags = merge(local.global_tags, {
    Name = "corp-${var.environment_name}-vpc-nat-gw-${each.key}"
  })

  depends_on = [aws_internet_gateway.terraform_igw]
}

# Resource-7: Public Route Table
resource "aws_route_table" "terraform_public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
  tags = merge(local.global_tags, { Name = "corp-${var.environment_name}-public-rt" })
}

# Resource-8: Public Route Table Associate to Public Subnet
resource "aws_route_table_association" "terraform_public_rt_assoc" {
  for_each       = aws_subnet.terraform_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terraform_public_rt.id
}

# Resource-9: Private Route Table
resource "aws_route_table" "terraform_private_rt" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform_nat[local.azs[0]].id
  }
  tags = merge(local.global_tags, { Name = "corp-${var.environment_name}-private-rt" })
}

# Resource-10: Private Route Table Association to Private Subnet
resource "aws_route_table_association" "terraform_private_rt_assoc" {
  for_each       = aws_subnet.terraform_private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.terraform_private_rt.id
}
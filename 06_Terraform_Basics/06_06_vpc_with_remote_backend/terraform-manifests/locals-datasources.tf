# Datasources
data "aws_availability_zones" "available" {
  state = "available"
}

# Locals Block
locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = [for k, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k)]
  private_subnets = [for k, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k + 10)]
  global_tags = {
    Environment = "NonProd"
    ManagedBy   = "Terraform"
    Owner       = "MarquisOfDeath"
    Source      = "Terraform_AWS_locals_block"
  }
}

/*

azs:-----
• What it does: It grabs a list of the first 3 Availability Zones (AZs) available in your AWS region (e.g., ["us-east-1a", "us-east-1b", "us-east-1c"]).
• How it works step-by-step:
	1. data.aws_availability_zones.available.names: This asks AWS for a list of all data center names in your current region. If you are in Virginia, it might return a list of 6 names: ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"].
	2. slice(..., 0, 3): The slice function acts like a cookie cutter. It takes the big list and cuts out a specific portion. It starts at index 0 (the 1st item) and stops just before index 3 (the 4th item).
	3. Result stored in local.azs: A clean list of exactly 3 data centers: ["us-east-1a", "us-east-1b", "us-east-1c"].

public_subnets:-----
• What it does: It loops through your 3 selected data centers and calculates 3 separate IP ranges (subnets) for your public internet-facing resources.
• How it works step-by-step:
	1. [for k, az in local.azs : ... ]: This is a for loop. It looks at the 3 data centers we just found.
		• az represents the name of the zone (like "us-east-1a").
		• k represents the index number/counter of the loop, starting at 0.
	2. cidrsubnet(...): This is a built-in Terraform math function that splits a large IP network into smaller networks. It takes 3 ingredients:
		• var.vpc_cidr: Your main massive network block (let's assume it is 10.0.0.0/16).
		• var.subnet_newbits: How much smaller you want to make the subnets. If this is 8, it converts a /16 network into /24 subnets (changing a network of 65,000 IPs into smaller blocks of 256 IPs).
		• k: The netnum (network number). This tells Terraform which piece of the chopped-up network to hand back.
	3. The Loop Mechanics:
		• Round 1: k = 0. The function calculates the 0th subnet block \(\rightarrow \) 10.0.0.0/24
		• Round 2: k = 1. The function calculates the 1st subnet block \(\rightarrow \) 10.0.1.0/24
		• Round 3: k = 2. The function calculates the 2nd subnet block \(\rightarrow \) 10.0.2.0/24
	4. Result stored in local.public_subnets: ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

private_subnets:-----
• What it does: It loops through those exact same 3 data centers, but calculates 3 different, isolated IP ranges for your private backend resources (like databases).
• Why the k + 10 matters:
If this line just used k, it would generate the exact same IP addresses as the public subnets (10.0.0.0/24, etc.), which would cause a critical IP conflict error.
By adding 10 to the counter, you tell Terraform to skip the first 10 slots in the network entirely and start building the private subnets further down the line.
• The Loop Mechanics:
	• Round 1: k = 0. (0 + 10 = 10). Calculates the 10th subnet block \(\rightarrow \) 10.0.10.0/24
	• Round 2: k = 1. (1 + 10 = 11). Calculates the 11th subnet block \(\rightarrow \) 10.0.11.0/24
	• Round 3: k = 2. (2 + 10 = 12). Calculates the 12th subnet block \(\rightarrow \) 10.0.12.0/24
• Result stored in local.private_subnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]


*/
# Terraform VPC Module – Single NAT Gateway Setup

![Terraform](https://img.shields.io/badge/Terraform-Module-623CE4?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![License](https://img.shields.io/badge/License-MIT-green)
![Maintained](https://img.shields.io/badge/Maintained-yes-brightgreen)
![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9C%94-blue)

> ⚠️ *This module is not yet published on the Terraform Registry.*  
> To use it, reference it locally or within your own GitHub repo.

---

## Features

- Provisions a **custom VPC** with user-defined CIDR block
- Public & private subnets across **up to 3 Availability Zones**
- Creates **a single NAT Gateway** for private subnets (cost-effective)
- Manages route tables and subnet associations
- Exports clean outputs to integrate with EC2, RDS, EKS etc.

---

## File Structure

| File                        | Purpose |
|-----------------------------|---------|

| `a_variables.tf`              | Input variables for customization |
| `b_locals-datasources.tf`     | AZ lookups and subnet CIDR logic |
| `c_main.tf`                   | Core resources: VPC, subnets, NAT gateway, routes |
| `d_outputs.tf`                | Output values to expose module data |
| `README.md`                   | Module usage and documentation |

---

## Usage

```hcl
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

> ⚠️ This module auto-detects up to **3 availability zones** using `data.aws_availability_zones`.

---

## Outputs


| Root Output Name (`root_mod_*`) | Child Output Name (`child_mod_*`) | Description |
| --- | --- | --- |
| `root_mod_vpc_id` | `child_mod_vpc_id` | The unique identifier of the core network VPC

 |
| `root_mod_vpc_cidr_block` | `child_mod_vpc_cidr_block` | The primary CIDR network block bound to the VPC

 |
| `root_mod_internet_gateway_id` | `child_mod_internet_gateway_id` | The unique identifier of the attached Edge Internet Gateway

 |
| `root_mod_public_subnet_ids` | `child_mod_public_subnet_ids` | Mapping of Availability Zones to Public Subnet IDs

 |
| `root_mod_public_subnet_cidrs` | `child_mod_public_subnet_cidrs` | Mapping of Availability Zones to Public Subnet CIDR blocks

 |
| `root_mod_private_subnet_ids` | `child_mod_private_subnet_ids` | List of Private Subnet IDs

 |
| `root_mod_private_subnet_cidrs` | `child_mod_private_subnet_cidrs` | List of Private Subnet CIDR blocks

 |
| `root_mod_nat_eip_public_ip` | `child_mod_nat_eip_public_ip` | The static external public Elastic IP bound to the outbound NAT Gateway

 |
| `root_mod_nat_gateway_id` | `child_mod_nat_gateway_id` | The unique identifier token of the single outbound NAT Gateway

 |
| `root_mod_public_route_table_id` | `child_mod_public_route_table_id` | The unique identifier of the Public Network Route Table

 |
| `root_mod_private_route_table_id` | `child_mod_private_route_table_id` | The unique identifier of the Private Network Route Table

 |


> You can use these outputs to pass subnet IDs to other modules (e.g., EC2, RDS, ALB, EKS).

---

## Best Practices

* Create **one NAT Gateway** per region when cost savings matter.
* Use `terraform.tfvars` or environment-specific tfvars files to reuse this module across `dev`, `test`, `prod`.
* All **private subnets**, regardless of AZ, should route outbound traffic through the **single NAT Gateway**.
*  Only **public subnets** should route through the **Internet Gateway (IGW)**.
* Enable remote state backend for team collaboration.

---

## Author

**Kalyan Reddy Daida**
Stacksimplify | Udemy Instructor
Course: *DevOps Real-world Project Implementation on AWS Cloud*

---


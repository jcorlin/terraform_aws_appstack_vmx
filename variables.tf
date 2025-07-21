variable "name_prefix" {
  type        = string
  description = "Prefix for naming managed resources"
}

variable "aws_region" {
  description = "AWS region - us-east-2"
  type        = string
}

# route53_zone_id
variable "route53_zone_id" {
  description = "The route53 zone ID for record creation"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones to use (e.g., [\"us-east-2a\", \"us-east-2b\"])"
  type        = list(string)
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for initial deployment. Required even if not needed"
  type        = string
}

# --- VPC ---
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_primary_sdwan_cidr" {
  description = "CIDR block for the primary AZ SD-WAN subnet"
  type        = string
}

variable "az_primary_public_cidr" {
  description = "CIDR block for the  primary AZ Public subnet"
  type        = string
}

variable "az_primary_private_cidr" {
  description = "CIDR block for the primary AZ Private subnet"
  type        = string
}

variable "az_primary_vmx_lan_cidr" {
  description = "CIDR block for the primary AZ MX LAN interface"
  type        = string
}

variable "az_secondary_sdwan_cidr" {
  description = "CIDR block for the secondary AZ SD-WAN subnet"
  type        = string
}

variable "az_secondary_public_cidr" {
  description = "CIDR block for the  secondary AZ Public subnet"
  type        = string
}

variable "az_secondary_private_cidr" {
  description = "CIDR block for the secondary AZ Private subnet"
  type        = string
}

variable "az_secondary_vmx_lan_cidr" {
  description = "CIDR block for the secondary AZ MX LAN interface"
  type        = string
}

variable "internal_ec2_sg_trusted_ranges" {
  description = "A list of CIDR blocks for trusted inbound access on the shared ec2 security group"
  type        = list(any)
}
# --- END VPC ---

# --- START MERAKI ---
variable "meraki_org_id" {
  type = string
}

variable "meraki_vmx_ami_id" {
  type = string
}

variable "vmx_az_primary_network_name" {
  type    = string
  default = "DEFAULT--Terraform-vMX-Network-PrimaryAZ"
}

variable "vmx_az_secondary_network_name" {
  type    = string
  default = "DEFAULT--Terraform-vMX-Network-SecondaryAZ"
}

variable "vmx_az_primary_wan_private_ip" {
  description = "Private IP(WAN) for the vMX instance in the primary AZ"
  type        = string
}

variable "vmx_az_secondary_wan_private_ip" {
  description = "Private IP(WAN) for the vMX instance in the secondary AZ"
  type        = string
}

variable "vmx_az_primary_lan_private_ip" {
  description = "Private IP(LAN) for the vMX instance in the primary AZ"
  type        = string
}

variable "vmx_az_secondary_lan_private_ip" {
  description = "Private IP(LAN) for the vMX instance in the secondary AZ"
  type        = string
}

variable "vmx_az_primary_return_route_cidrs" {
  description = "CIDRs to return route via the primary vMX"
  type        = list(string)
  default     = []
}

variable "vmx_az_secondary_return_route_cidrs" {
  description = "CIDRs to return route via the secondary vMX"
  type        = list(string)
  default     = []
}
# --- END MERAKI ---

# --- START EC2 ---
variable "apphost_ami_id" {
  type = string
}

variable "az_primary_ubuntu1_private_ip" {
  description = "Static private IP for the Public Ubuntu instance - generic"
  type        = string
}

variable "az_secondary_ubuntu1_private_ip" {
  description = "Static private IP for the Private Ubuntu instance - app host"
  type        = string
}

# Example app host vars
#
#variable "az_primary_ubuntu2_private_ip" {
#  description = "Static private IP for the Public Ubuntu instance - generic"
#  type        = string
#}
#
#variable "az_secondary_ubuntu2_private_ip" {
#  description = "Static private IP for the Private Ubuntu instance - app host"
#  type = string
#}
# --- END EC2 ---


# --- START ECS --- 
variable "ecs_apps" {
  description = "Map of ECS app definitions, keyed by app label"
  type = map(object({
    az_primary = object({
      # subnet_ids          = list(string)
      private_dns_name = string
      # private_ip_address  = string
    })
    az_secondary = object({
      # subnet_ids          = list(string)
      private_dns_name = string
      # private_ip_address  = string
    })
    app_container_image = string
    tls_sidecar_image   = string
    container_cpu       = optional(number, 512)
    container_memory    = optional(number, 1024)
    desired_count       = optional(number, 1)
    assign_public_ip    = optional(bool, false)
  }))
}

# Aurora RDS
variable "db_name" {
  description = "Initial database name for the application"
  type        = string
  default     = "myappdb" # Replace or override as needed
}

variable "db_engine" {
  description = "Database engine for RDS/Aurora"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  description = "Engine version for Aurora PostgreSQL"
  type        = string
  default     = "15.4"
}

variable "db_user" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master user password"
  type        = string
  sensitive   = true
}

# CERTDNS / ALB
variable "hosted_zone_name" {
  type        = string
  description = "Route 53 hosted zone (e.g. company.com.)"
}

variable "app_dns_cname" {
  type        = string
  description = "Fully-qualified domain name for the app (e.g. mysite.company.com)"
}

variable "create_alias" {
  type        = bool
  description = "Whether to create a Route 53 alias record pointing to the ALB"
  default     = false
}

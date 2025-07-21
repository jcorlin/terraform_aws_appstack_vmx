variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for AZ selection)"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
}

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

variable "internal_ec2_sg_trusted_ranges" {
  description = "A list of CIDR blocks for trusted inbound access on the shared ec2 security group"
  type        = list(any)
}

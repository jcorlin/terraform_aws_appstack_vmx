variable "name_prefix" {
  description = "Prefix for all resource names and tags"
  type        = string
}

variable "availability_zone" {
  type = string
}

# AWS VARS
variable "subnet_id" {
  description = "Subnet ID to launch the vMX in"
  type        = string
}

variable "aws_vpc_id" {
  description = "VPC ID where the vMX and security group will be deployed"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the vMX"
  type        = string
  default     = "t3.medium"
}

variable "meraki_vmx_ami_id" {
  description = "AMI ID for Cisco Meraki vMX"
  type        = string
}

variable "wan_security_group_ids" {
  description = "ID(s) of the shared security group(s) to attach to the WAN(primary) interface"
  type        = list(any)
}

variable "lan_security_group_ids" {
  description = "ID(s) of the shared security group(s) to attach to the LAN(secondary) interface"
  type        = list(any)
}

# Meraki VARS
variable "meraki_org_id" {
  type = string
}

variable "vmx_network_name" {
  type = string
}

variable "vmx_lan_cidr" {
  type = string
}

variable "vmx_wan_private_ip" {
  description = "Private IP for the vMX WAN interface"
  type        = string
}

variable "vmx_lan_private_ip" {
  description = "Private IP for the vMX LAN interface"
  type        = string
}

variable "wan_route_table_id" {
  description = "ID of the route table for the WAN interface subnet"
  type        = string
}

variable "return_route_cidrs" {
  description = "List of CIDR blocks to route to the vMX instance(typically AutoVPN spoke ranges)"
  type        = list(string)
  default     = []
}

variable "vmx_claim_delay_seconds" {
  description = "Delay in seconds to wait after network creation, before claiming vMX"
  type        = number
  default     = 15
}

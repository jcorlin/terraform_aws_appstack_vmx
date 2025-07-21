variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of SG IDs to apply to the instance"
  type        = list(string)
  default     = []
}

variable "private_ip" {
  description = "The private IP for the ec2 instance primary interface"
  type        = string
}

variable "hostname" {
  description = "A descriptive name for the instance."
  type        = string
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address to the instance - true/false."
  type        = bool
}

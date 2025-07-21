variable "name_prefix" {
  type        = string
  description = "Name prefix for the Transit Gateway"
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
}

variable "db_user" {
  description = "Master username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master user password for the database"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs across AZs for the RDS cluster"
  type        = list(string)
}

variable "preferred_subnet_index" {
  description = "Index of the subnet where the writer should be placed (best effort)"
  type        = number
  default     = 0
}

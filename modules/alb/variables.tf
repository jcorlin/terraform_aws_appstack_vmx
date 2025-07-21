variable "enabled" {
  type    = bool
  default = true
}

variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "acm_cert_arn" {
  type = string
}

variable "az_primary_target_instance_id" {
  type    = string
  default = ""
}

variable "az_secondary_target_instance_id" {
  type    = string
  default = ""
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID for DNS record"
  type        = string
}

variable "app_dns_cname" {
  description = "User-facing DNS record (e.g., app.example.com)"
  type        = string
}

variable "hosted_zone_name" {
  type        = string
  description = "Route 53 hosted zone name (e.g., company.com.)"
}

variable "create_alias" {
  type        = bool
  description = "Whether to create a Route 53 alias record pointing to the ALB"
  default     = false
}

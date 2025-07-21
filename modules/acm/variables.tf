variable "name_prefix" {
  type = string
}

variable "app_dns_cname" {
  type = string
}

variable "hosted_zone_name" {
  type        = string
  description = "Route 53 hosted zone name (e.g., company.com.)"
}

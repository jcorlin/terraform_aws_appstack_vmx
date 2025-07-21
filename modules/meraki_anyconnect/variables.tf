#variable "meraki_api_key" {
#  description = "Meraki API key"
#  type        = string
#}

variable "network_id" {
  description = "Meraki network ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region for Route 53"
  type        = string
}

variable "acme_email" {
  description = "Email used for ACME account registration"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "vpn_ipv4_address" {
  description = "IPv4 address to assign to the VPN A record"
  type        = string
}

#variable "csr_subject" {
#  description = "PEM-encoded subject name for the CSR, e.g., CN=vpn.example.com"
#  type        = string
#}

variable "anyconnect_hostname" {
  description = "The FQDN to use for AnyConnect VPN cert and A record (e.g., vpn.example.com)"
  type        = string
}

variable "anyconnect_landing_page" {
  description = "Landing page for AnyConnect"
  type        = string
}

variable "split_dns" {
  description = "List of split DNS domains"
  type        = list(string)
  default     = []
}

variable "radius_servers" {
  description = "List of RADIUS server configurations"
  type = list(object({
    host   = string
    port   = number
    secret = string
  }))
}

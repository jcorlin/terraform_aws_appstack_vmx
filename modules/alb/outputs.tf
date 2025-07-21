output "alb_dns_name" {
  value       = var.enabled ? aws_lb.app[0].dns_name : ""
  description = "The DNS name of the ALB"
}

output "alb_zone_id" {
  value       = var.enabled ? aws_lb.app[0].zone_id : ""
  description = "The Route 53 zone ID for use with alias records"
}

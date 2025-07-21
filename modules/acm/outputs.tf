output "certificate_arn" {
  value       = aws_acm_certificate.cert.arn
  description = "ARN of the ACM certificate"
}

output "route53_zone_id" {
  value       = data.aws_route53_zone.this.zone_id
  description = "Hosted zone ID used for DNS validation"
}

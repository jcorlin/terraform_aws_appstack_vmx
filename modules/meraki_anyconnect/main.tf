resource "meraki_mx_client_vpn_cert" "csr" {
  network_id = var.network_id
  generate   = true
  subject    = "CN=${var.anyconnect_hostname}"
}

resource "tls_private_key" "acme_account" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.acme_account.private_key_pem
  email_address   = var.acme_email
}

resource "acme_certificate" "signed_cert" {
  account_key_pem = acme_registration.reg.account_key_pem
  csr_pem         = meraki_mx_client_vpn_cert.csr.csr

  dns_challenge {
    provider = "route53"
  }
}

resource "aws_route53_record" "acme_challenge" {
  for_each = {
    for dvo in acme_certificate.signed_cert.dns_challenges : dvo.domain => dvo
  }

  zone_id = var.route53_zone_id
  name    = each.value.record_name
  type    = each.value.record_type
  ttl     = 60
  records = [each.value.record_value]
}

resource "aws_route53_record" "vpn_a_record" {
  zone_id = var.route53_zone_id
  name    = var.anyconnect_hostname
  type    = "A"
  ttl     = 300
  records = [var.vpn_ipv4_address]
}

resource "meraki_mx_client_vpn_cert" "signed" {
  network_id         = var.network_id
  signed_certificate = acme_certificate.signed_cert.certificate_pem
  intermediate_cert  = acme_certificate.signed_cert.issuer_pem
}

resource "meraki_network_client_vpn" "vpn_config" {
  network_id           = var.network_id
  mode                 = "enabled"
  radius_servers       = var.radius_servers
  dns_nameservers      = "google"
  anyconnect_enabled   = true
  anyconnect_landing   = var.anyconnect_landing_page
  anyconnect_issuer    = "custom"
  anyconnect_identity  = "radius"
  anyconnect_cert_type = "custom"
  anyconnect_split_dns = var.split_dns
}

terraform {
  required_providers {
    meraki = {
      source  = "cisco-open/meraki"
      version = "1.1.6-beta"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = ">= 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  email      = var.acme_email
}

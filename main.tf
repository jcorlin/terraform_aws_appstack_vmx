terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    meraki = {
      source  = "cisco-open/meraki"
      version = "1.1.6-beta"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# easy reference for AZs
locals {
  az_primary   = var.availability_zones[0]
  az_secondary = var.availability_zones[1]
}

# --- VPC Module ---
module "vpc" {
  source = "./modules/vpc"

  name_prefix                    = var.name_prefix
  aws_region                     = var.aws_region
  availability_zones             = var.availability_zones
  vpc_cidr_block                 = var.vpc_cidr_block
  az_primary_sdwan_cidr          = var.az_primary_sdwan_cidr
  az_primary_public_cidr         = var.az_primary_public_cidr
  az_primary_private_cidr        = var.az_primary_private_cidr
  az_secondary_sdwan_cidr        = var.az_secondary_sdwan_cidr
  az_secondary_public_cidr       = var.az_secondary_public_cidr
  az_secondary_private_cidr      = var.az_secondary_private_cidr
  internal_ec2_sg_trusted_ranges = var.internal_ec2_sg_trusted_ranges
}

# --- Meraki vMX - AZ Primary ---
module "vmx_az_primary" {
  source = "./modules/meraki"

  name_prefix             = var.name_prefix
  availability_zone       = local.az_primary
  aws_vpc_id              = module.vpc.vpc_id
  meraki_vmx_ami_id       = var.meraki_vmx_ami_id
  meraki_org_id           = var.meraki_org_id
  vmx_network_name        = var.vmx_az_primary_network_name
  vmx_wan_private_ip      = var.vmx_az_primary_wan_private_ip
  wan_route_table_id      = module.vpc.public_route_table_id
  vmx_lan_cidr            = var.az_primary_vmx_lan_cidr
  vmx_lan_private_ip      = var.vmx_az_primary_lan_private_ip
  return_route_cidrs      = var.vmx_az_primary_return_route_cidrs
  subnet_id               = module.vpc.sdwan_subnet_ids[0] # Use first SD-WAN subnet - primary AZ
  ssh_key_name            = var.ssh_key_name
  wan_security_group_ids  = [module.vpc.internal_ec2_sg_id, module.vpc.https_allow_any_group_id]
  lan_security_group_ids  = [module.vpc.allow_any_group_id]
  instance_type           = "c5.large"
  vmx_claim_delay_seconds = 15

  depends_on = [
    module.vpc # Ensures all resources in the VPC module are complete 
  ]

}

# --- Meraki vMX - AZ Secondary ---
module "vmx_az_secondary" {
  source = "./modules/meraki"

  name_prefix            = var.name_prefix
  availability_zone      = local.az_secondary
  aws_vpc_id             = module.vpc.vpc_id
  meraki_vmx_ami_id      = var.meraki_vmx_ami_id
  meraki_org_id          = var.meraki_org_id
  vmx_network_name       = var.vmx_az_secondary_network_name
  vmx_wan_private_ip     = var.vmx_az_secondary_wan_private_ip
  wan_route_table_id     = module.vpc.public_route_table_id
  vmx_lan_cidr           = var.az_secondary_vmx_lan_cidr
  vmx_lan_private_ip     = var.vmx_az_secondary_lan_private_ip
  return_route_cidrs     = var.vmx_az_secondary_return_route_cidrs
  subnet_id              = module.vpc.sdwan_subnet_ids[1] # Use second SD-WAN subnet - secondary AZ
  ssh_key_name           = var.ssh_key_name
  wan_security_group_ids = [module.vpc.internal_ec2_sg_id, module.vpc.https_allow_any_group_id]
  lan_security_group_ids = [module.vpc.allow_any_group_id]
  instance_type          = "c5.large"

  vmx_claim_delay_seconds = 30

  depends_on = [
    module.vpc
  ]

}

# 
# --- ECS Web App with TLS Sidecar - AZ Primary ---
# 

resource "aws_ecs_cluster" "app_ecs_cluster" {
  name = "${var.name_prefix}-cluster"
}

# --- ECS Web App with TLS Sidecar - AZ Primary ---
module "ecs_djangotestapp" {
  source = "./modules/ecs_app_with_tlssc"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.internal_ec2_sg_id]
  ecs_cluster_id     = aws_ecs_cluster.app_ecs_cluster.id
  container_image    = var.ecs_apps["djangotestapp"].app_container_image
  container_name     = "django-test-app"
  sidecar_image      = var.ecs_apps["djangotestapp"].tls_sidecar_image
  private_dns_name   = var.ecs_apps["djangotestapp"].az_primary.private_dns_name
  container_cpu      = var.ecs_apps["djangotestapp"].container_cpu
  container_memory   = var.ecs_apps["djangotestapp"].container_memory
  desired_count      = var.ecs_apps["djangotestapp"].desired_count
  assign_public_ip   = var.ecs_apps["djangotestapp"].assign_public_ip
  route53_zone_id    = var.route53_zone_id

}

# ---PUBLIC UBUNTU SERVER - AZ PRIMARY ---
module "az_primary_ubuntu_proxyhost" {
  source = "./modules/ec2"

  name_prefix                 = var.name_prefix
  ami_id                      = var.apphost_ami_id
  instance_type               = "t3.medium"
  ssh_key_name                = var.ssh_key_name
  subnet_id                   = module.vpc.public_subnet_ids[0] # Public NET - Primary AZ
  private_ip                  = var.az_primary_ubuntu1_private_ip
  hostname                    = "AWS-USE2-AZP-PROXY1"
  security_group_ids          = [module.vpc.https_allow_any_group_id, module.vpc.internal_ec2_sg_id]
  associate_public_ip_address = true

  depends_on = [
    module.ecs_djangotestapp
  ]

}

# ---PUBLIC UBUNTU SERVER - AZ SECONDARY ---
module "az_secondary_ubuntu_proxyhost" {
  source = "./modules/ec2"

  name_prefix                 = var.name_prefix
  ami_id                      = var.apphost_ami_id
  instance_type               = "t3.medium"
  ssh_key_name                = var.ssh_key_name
  subnet_id                   = module.vpc.public_subnet_ids[1] # Public NET - Secondary AZ
  private_ip                  = var.az_secondary_ubuntu1_private_ip
  hostname                    = "AWS-USE2-AZS-PROXY1"
  security_group_ids          = [module.vpc.https_allow_any_group_id, module.vpc.internal_ec2_sg_id]
  associate_public_ip_address = true

  depends_on = [
    module.ecs_djangotestapp
  ]

}

#
# --- EXAMPLE OF EC2 BASED APP HOST OPTION ---
#
# --- PRIVATE UBUNTU SERVER - AZ PRIMARY ---
#module "az_primary_ubuntu_apphost" {
#  source                        = "./modules/ec2"

#  name_prefix                   = var.name_prefix
#  ami_id                        = var.apphost_ami_id 
#  instance_type                 = "t3.medium"
#  ssh_key_name                  = var.ssh_key_name
#  subnet_id                     = module.vpc.private_subnet_ids[0]   # Public NET - Primary AZ
#  private_ip                    = var.az_primary_ubuntu2_private_ip
#  hostname                      = "AWS-USE2-AZP-APP1"  
#  vpc_id                        = module.vpc.vpc_id
#  security_group_ids            = [module.vpc.https_allow_any_group_id, module.vpc.internal_ec2_sg_id]
#  associate_public_ip_address   = false
#}

# ---PRIVATE UBUNTU SERVER - AZ SECONDARY ---
#module "az_secondary_ubuntu_apphost" {
#  source                        = "./modules/ec2"

#  name_prefix                   = var.name_prefix
#  ami_id                        = var.apphost_ami_id 
#  instance_type                 = "t3.medium"
#  ssh_key_name                  = var.ssh_key_name
#  subnet_id                     = module.vpc.private_subnet_ids[1]   # Public NET - Secondary AZ
#  private_ip                    = var.az_secondary_ubuntu2_private_ip
#  hostname                      = "AWS-USE2-AZS-APP1"
#  vpc_id                        = module.vpc.vpc_id
#  security_group_ids            = [module.vpc.https_allow_any_group_id, module.vpc.internal_ec2_sg_id]
#  associate_public_ip_address   = false
#}

# --- AURORA RDS ---
module "rds" {
  source                 = "./modules/rds"
  name_prefix            = var.name_prefix
  db_name                = var.db_name
  db_user                = var.db_user
  db_password            = var.db_password
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  preferred_subnet_index = 0
}

# ---CERTIFICATES ---

module "acm" {
  source           = "./modules/acm"
  name_prefix      = var.name_prefix
  app_dns_cname    = var.app_dns_cname
  hosted_zone_name = var.hosted_zone_name

  depends_on = [
    module.vpc
  ]

}

# ---APP LOAD BALANCER ---
module "alb" {
  source                          = "./modules/alb"
  enabled                         = true
  name_prefix                     = var.name_prefix
  subnet_ids                      = module.vpc.public_subnet_ids
  security_group_id               = module.vpc.https_allow_any_group_id
  vpc_id                          = module.vpc.vpc_id
  acm_cert_arn                    = module.acm.certificate_arn
  hosted_zone_name                = var.hosted_zone_name
  route53_zone_id                 = var.route53_zone_id
  app_dns_cname                   = var.app_dns_cname
  az_primary_target_instance_id   = module.az_primary_ubuntu_proxyhost.instance_id # point at ubuntu instance in public subnet running nginx reverse proxy
  az_secondary_target_instance_id = module.az_secondary_ubuntu_proxyhost.instance_id

  depends_on = [
    module.acm
  ]
}

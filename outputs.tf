output "vpc" {
  description = "VPC and networking resources"
  value = {
    vpc_id = module.vpc.vpc_id
    igw_id = module.vpc.igw_id
  }
}

output "reverse_proxies" {
  description = "Public reverse proxy instances handling WebSocket traffic"
  value = {
    az_primary = {
      instance_id = module.az_primary_ubuntu_proxyhost.instance_id
      public_ip   = module.az_primary_ubuntu_proxyhost.public_ip
    }
    az_secondary = {
      instance_id = module.az_secondary_ubuntu_proxyhost.instance_id
      public_ip   = module.az_secondary_ubuntu_proxyhost.public_ip
    }
  }
}

output "vmx" {
  description = "Meraki vMX public endpoints and serials"
  value = {
    az_primary = {
      serial        = module.vmx_az_primary.vmx_serial
      public_ip     = module.vmx_az_primary.vmx_public_ip
      dashboard_url = module.vmx_az_primary.vmx_dashboard_network_url
    }
    az_secondary = {
      serial        = module.vmx_az_secondary.vmx_serial
      public_ip     = module.vmx_az_secondary.vmx_public_ip
      dashboard_url = module.vmx_az_secondary.vmx_dashboard_network_url
    }
  }
}

output "ecs_django_app" {
  description = "ECS Django application container details"
  value = {
    cluster_name        = aws_ecs_cluster.app_ecs_cluster.name
    service_name        = module.ecs_djangotestapp.ecs_service_name
    service_id          = module.ecs_djangotestapp.ecs_service_id
    task_definition_arn = module.ecs_djangotestapp.ecs_task_definition_arn
    task_role_arn       = module.ecs_djangotestapp.ecs_task_role_arn
    execution_role_arn  = module.ecs_djangotestapp.ecs_execution_role_arn
  }
}

output "alb" {
  description = "Application Load Balancer and Route 53 integration"
  value = {
    dns_name = module.alb.alb_dns_name
    zone_id  = module.alb.alb_zone_id
  }
}

output "acm" {
  description = "TLS certificate and hosted zone details"
  value = {
    certificate_arn = module.acm.certificate_arn
    route53_zone_id = module.acm.route53_zone_id
  }
}

output "rds" {
  description = "Aurora PostgreSQL cluster connection details"
  value = {
    writer_endpoint      = module.rds.writer_endpoint
    reader_endpoint      = module.rds.reader_endpoint
    db_name              = module.rds.db_name
    security_group_id    = module.rds.security_group_id
    db_subnet_group_name = module.rds.db_subnet_group_name
  }
}

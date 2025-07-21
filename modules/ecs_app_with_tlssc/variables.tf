variable "name_prefix" {
  description = "App name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS service will run"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "container_image" {
  description = "Full URI of the app container image (e.g. ECR repo)"
  type        = string
}

variable "container_name" {
  description = "Name of the main application container"
  type        = string
}

variable "sidecar_image" {
  description = "Full URI of the TLS sidecar container image"
  type        = string
}

variable "private_dns_name" {
  description = "Private DNS name to register in Route 53"
  type        = string
}

variable "container_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  default     = 512
}

variable "container_memory" {
  description = "Fargate memory in MB"
  default     = 1024
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  default     = 1
}

variable "security_group_ids" {
  description = "Security groups for the ECS service ENIs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to the Fargate task ENI"
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 private zone ID for registering the service"
  type        = string
}

# variable "service_discovery_namespace_id" {
#   description = "Cloud Map namespace ID for ECS service discovery"
#   type        = string
# }

# variable "service_discovery_namespace_name" {
#   description = "Cloud Map namespace name (e.g. 'ecs.internal')"
#   type        = string
# }

# variable "service_discovery_registry_arn" {
#   description = "Cloud Map registry ARN"
#   type        = string
# }

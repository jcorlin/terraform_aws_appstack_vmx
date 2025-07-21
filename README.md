# Hybrid Cloud Lab Infrastructure

## Overview
This Terraform project provisions a fully functional dual-AZ, production-ready AWS VPC, designed to support secure, scalable workloads with minimal deployment effort required. 
The topology is purpose-built to support cloud connectivity via AutoVPN with redundant Cisco Meraki vMX deployments.

It includes complete routing, subnet design, and path redundancy, with tagging and dependency mappings to ensure consistent, predictable deployments that are easy to navigate in the UI.

## Phase Summary
- **Phase 1**: Core VPC foundation and AutoVPN interconnect via Cisco Meraki vMX  
- **Phase 2**: Application stack, batteries included — ECS, RDS, ALB, and flexible EC2 proxy tier

## Modules
| Module       | Purpose                                                |
|--------------|--------------------------------------------------------|
| `vpc`        | Dual-AZ VPC with subnets, NAT gateways, routing        |
| `meraki`     | Deploys Cisco Meraki vMX + AutoVPN peering             |
| `ec2`        | EC2-based NGINX reverse proxy and admin access point   |
| `ecs`        | Containerized app deployment using ECS Fargate         |
| `alb`        | Application Load Balancer with TLS and Route 53 DNS    |
| `rds`        | Amazon Aurora PostgreSQL cluster in private subnets    |
| `acm`        | TLS cert issuance using ACM + Route 53 DNS validation  |

## Getting Started
- Clone the repo
- customize your `terraform.tfvars` file with the appropriate CIDRs, AMI IDs, and DNS settings

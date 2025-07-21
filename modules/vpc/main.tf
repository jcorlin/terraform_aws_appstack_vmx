terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true # Required for internal DNS resolution
  enable_dns_hostnames = true # Required for assigning DNS names to ENIs

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_eip" "eip_nat_gw_az_primary" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-eip-nat-gw-az-primary"
  }
}

resource "aws_eip" "eip_nat_gw_az_secondary" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-eip-nat-gw-az-secondary"
  }
}

resource "aws_nat_gateway" "nat_az_primary" {
  allocation_id = aws_eip.eip_nat_gw_az_primary.id
  subnet_id     = aws_subnet.az_primary_public_net.id
  tags = {
    Name = "${var.name_prefix}-nat-gw-az-primary"
  }
}

resource "aws_nat_gateway" "nat_az_secondary" {
  allocation_id = aws_eip.eip_nat_gw_az_secondary.id
  subnet_id     = aws_subnet.az_secondary_public_net.id
  tags = {
    Name = "${var.name_prefix}-nat-gw-az-secondary"
  }
}

resource "aws_subnet" "az_primary_sdwan_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_primary_sdwan_cidr
  availability_zone       = local.az_primary
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-net-sd-wan-az-primary"
  }
}

resource "aws_subnet" "az_primary_public_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_primary_public_cidr
  availability_zone       = local.az_primary
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-net-public-az-primary"
  }
}

resource "aws_subnet" "az_primary_private_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_primary_private_cidr
  availability_zone       = local.az_primary
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name_prefix}-net-private-az-primary"
  }
}

resource "aws_subnet" "az_secondary_sdwan_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_secondary_sdwan_cidr
  availability_zone       = local.az_secondary
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-net-sd-wan-az-secondary"
  }
}

resource "aws_subnet" "az_secondary_public_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_secondary_public_cidr
  availability_zone       = local.az_secondary
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-net-public-az-secondary"
  }
}

resource "aws_subnet" "az_secondary_private_net" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.az_secondary_private_cidr
  availability_zone       = local.az_secondary
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name_prefix}-net-private-az-secondary"
  }
}

# Look up the default route table for the VPC
#data "aws_route_table" "default_at_creation_main_rt" {
#  vpc_id = aws_vpc.main.id
#
#  filter {
#    name   = "association.main"
#    values = ["true"]
#  }
#
#  depends_on = [aws_vpc.main]
#}

# Tag default RT it to DO NOT USE
#resource "aws_ec2_tag" "default_rtb_name_tag" {
#  resource_id = data.aws_route_table.default_at_creation_main_rt.id
#  key         = "Name"
#  value       = "z-DEFAULT-RT-DO-NOT-USE"
#
#  depends_on = [data.aws_route_table.default_at_creation_main_rt]
#}

#resource "aws_ec2_tag" "default_rtb_name_tag" {
#  resource_id = aws_vpc.main.default_route_table_id
#  key         = "Name"
#  value       = "z-DEFAULT-RT-DO-NOT-USE"
#} 

# Create new public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  #route {
  #  cidr_block = "0.0.0.0/0"
  #  gateway_id = aws_internet_gateway.igw.id
  #}

  tags = {
    Name = "${var.name_prefix}-rt-public"
  }
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  depends_on = [aws_internet_gateway.igw]

}

resource "aws_route_table_association" "rta_az_primary_sdwan_net" {
  subnet_id      = aws_subnet.az_primary_sdwan_net.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_az_primary_public_net" {
  subnet_id      = aws_subnet.az_primary_public_net.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_az_secondary_sdwan_net" {
  subnet_id      = aws_subnet.az_secondary_sdwan_net.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_az_secondary_public_net" {
  subnet_id      = aws_subnet.az_secondary_public_net.id
  route_table_id = aws_route_table.public_rt.id
}

# private AWS to NAT Primary
# private route table - primary az
resource "aws_route_table" "private_rt_az_primary" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rt-private-az-primary"
  }
}

resource "aws_route" "private_to_nat_az_primary" {
  route_table_id         = aws_route_table.private_rt_az_primary.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az_primary.id
}

resource "aws_route_table_association" "rta_az_primary_private_net" {
  subnet_id      = aws_subnet.az_primary_private_net.id
  route_table_id = aws_route_table.private_rt_az_primary.id
}

# private AWS to NAT Secondary
# private route table - secondary az
resource "aws_route_table" "private_rt_az_secondary" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-rt-private-az-secondary"
  }
}
resource "aws_route" "private_to_nat_az_secondary" {
  route_table_id         = aws_route_table.private_rt_az_secondary.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_az_secondary.id
}

resource "aws_route_table_association" "rta_az_secondary_private_net" {
  subnet_id      = aws_subnet.az_secondary_private_net.id
  route_table_id = aws_route_table.private_rt_az_secondary.id
}

# SECURITY GROUPS 
resource "aws_security_group" "allow_https_from_any" {
  name        = "ALLOW_HTTPS_FROM_ANY"
  description = "Allow inbound HTTPS (TCP 443) from any IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS from anywhere - PLACEHOLDER"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_ec2_sg_trusted_ranges
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.internal_ec2_sg_trusted_ranges
  }

  tags = {
    Name = "allow_https_from_any_placeholder"
  }
}

resource "aws_security_group" "internal_ec2_sg" {
  name        = "${var.name_prefix}-INTERNAL-EC2-SG"
  description = "EC2 Security Group for inbound access from internal resources."
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.internal_ec2_sg_trusted_ranges
    description = "Allow SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.internal_ec2_sg_trusted_ranges
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_ec2_sg_trusted_ranges
    description = "Allow HTTPS"
  }

  ingress {
    description = "Allow all traffic from RFC1918 Class A and B"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "10.0.0.0/8",   # Class A
      "172.16.0.0/12" # Class B
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}

resource "aws_security_group" "allow_any" {
  name        = "${var.name_prefix}-EC2-SG-ALLOW-ANY-ANY"
  description = "EC2 Security Group for MX LAN Interface"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg-allow-ip-any-any"
  }
}

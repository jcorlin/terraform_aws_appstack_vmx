output "vpc_id" {
  value = aws_vpc.main.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

# ROUTE TABLES
output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

output "private_route_table_az_primary_id" {
  value = aws_route_table.private_rt_az_primary.id
}

output "private_route_table_az_secondary_id" {
  value = aws_route_table.private_rt_az_secondary.id
}

# SUBNETS
output "sdwan_subnet_ids" {
  value = [
    aws_subnet.az_primary_sdwan_net.id, # original SD-WAN subnet
    aws_subnet.az_secondary_sdwan_net.id
  ]
}

output "public_subnet_ids" {
  value = [
    aws_subnet.az_primary_public_net.id,
    aws_subnet.az_secondary_public_net.id,
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.az_primary_private_net.id,
    aws_subnet.az_secondary_private_net.id,
  ]
}

# SECURITY GROUPS
output "internal_ec2_sg_id" {
  value = aws_security_group.internal_ec2_sg.id
}

output "https_allow_any_group_id" {
  value = aws_security_group.allow_https_from_any.id
}

output "allow_any_group_id" {
  value = aws_security_group.allow_any.id
}

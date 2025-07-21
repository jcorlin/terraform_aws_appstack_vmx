

# Create a Meraki Network with vMX-M
resource "meraki_networks" "vmx_network" {
  organization_id = var.meraki_org_id
  name            = var.vmx_network_name
  product_types   = ["appliance"]
  time_zone       = "America/Chicago"
  tags            = ["terraform", "vmx"]
  notes           = "Terraform-managed vMX-M network"
}

resource "meraki_networks_appliance_single_lan" "vmx_lan_interface_dashboard" {
  network_id   = meraki_networks.vmx_network.id
  subnet       = var.vmx_lan_cidr
  appliance_ip = var.vmx_lan_private_ip

  depends_on = [meraki_networks.vmx_network]
}

resource "null_resource" "wait_after_network_creation" {
  depends_on = [meraki_networks.vmx_network]

  provisioner "local-exec" {
    command = <<EOT
echo "[${var.vmx_network_name}] Sleep start: $(date '+%Y-%m-%d %H:%M:%S')"
sleep ${var.vmx_claim_delay_seconds}
echo "[${var.vmx_network_name}] Sleep end:   $(date '+%Y-%m-%d %H:%M:%S')"
EOT
  }
}

resource "meraki_networks_devices_claim_vmx" "vmx_appliance" {

  network_id = meraki_networks.vmx_network.id
  parameters = {

    size = "medium"
  }
  depends_on = [null_resource.wait_after_network_creation]
}

# Generate the vMX token
resource "meraki_devices_appliance_vmx_authentication_token" "vmx_token" {
  serial = meraki_networks_devices_claim_vmx.vmx_appliance.item.serial

  depends_on = [meraki_networks_devices_claim_vmx.vmx_appliance]

}

resource "aws_instance" "vmx" {

  ami                         = var.meraki_vmx_ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  private_ip                  = var.vmx_wan_private_ip
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = var.wan_security_group_ids
  source_dest_check           = false # Allow Cisco Meraki vMX to forward AutoVPN Traffic to VPC

  metadata_options {
    http_endpoint = "enabled"  # Ensure metadata accessible is enabled
    http_tokens   = "optional" # This allows IMDSv1 (required for vMX as of May 2025)
  }
  user_data = meraki_devices_appliance_vmx_authentication_token.vmx_token.item.token

  tags = {
    Name = "${var.name_prefix}-vMX"
  }


  depends_on = [meraki_devices_appliance_vmx_authentication_token.vmx_token]

}

resource "aws_subnet" "vmx_lan_net" {
  vpc_id                  = var.aws_vpc_id #aws_vpc.main.id
  cidr_block              = var.vmx_lan_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name_prefix}-NET-MX-LAN"
  }
}

# Create a second ENI for vMX LAN
resource "aws_network_interface" "vmx_lan" {
  subnet_id       = aws_subnet.vmx_lan_net.id
  private_ips     = [var.vmx_lan_private_ip]
  security_groups = var.lan_security_group_ids

  tags = {
    Name = "${var.name_prefix}-IFACE-MX-LAN"
  }
}

# Attach the ENI to the vMX instance
resource "aws_network_interface_attachment" "vmx_lan_attach" {
  instance_id          = aws_instance.vmx.id
  network_interface_id = aws_network_interface.vmx_lan.id
  device_index         = 1 # 0 = primary, 1 = second interface
}

# LAN Route
resource "aws_route" "vmx_routes" {
  for_each = toset(var.return_route_cidrs)

  route_table_id         = var.wan_route_table_id
  destination_cidr_block = each.value
  network_interface_id   = aws_instance.vmx.primary_network_interface_id

  #lifecycle {
  #  create_before_destroy = true
  #}

  depends_on = [aws_instance.vmx]

}

resource "aws_route_table" "vmx_lan_rt" {
  vpc_id = var.aws_vpc_id

  tags = {
    Name = "${var.name_prefix}-VMX-LAN-RT"
  }
}

resource "aws_route_table_association" "rta_vmx_lan_net" {
  subnet_id      = aws_subnet.vmx_lan_net.id
  route_table_id = aws_route_table.vmx_lan_rt.id
}

resource "aws_route" "vmx_lan_rt_default_route" {
  route_table_id         = aws_route_table.vmx_lan_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.vmx.primary_network_interface_id
}

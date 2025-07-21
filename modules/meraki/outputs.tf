output "vmx_instance_id" {
  value = aws_instance.vmx.id
}

output "vmx_public_ip" {
  value = aws_instance.vmx.public_ip
}

output "vmx_dashboard_network_id" {
  value = meraki_networks.vmx_network.id
}

output "vmx_dashboard_network_url" {
  value = meraki_networks.vmx_network.url
}

output "vmx_serial" {
  value = meraki_networks_devices_claim_vmx.vmx_appliance.item.serial
}

# output "vmx_token" {
#  value       = meraki_network_appliance_vm_provision.vmx_token.token
#  description = "Token to register the vMX - AWS User Data"
#  sensitive   = true
#}

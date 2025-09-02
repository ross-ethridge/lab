// Output Ip Addresses

output "ControlPlane" {
  value = vsphere_virtual_machine.kubemaster[0].default_ip_address
}

# output "Workers" {
#   value = {
#     for instance in vsphere_virtual_machine.kubeworker :
#     instance.name => instance.default_ip_address
#   }
# }

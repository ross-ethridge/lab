// vsphere datacenter the virtual machine will be deployed to.
variable "vsphere_datacenter" {
  type = string
}

// vsphere datastore for even numbered machines.
variable "vsphere_datastore" {
  type = string
}

// vsphere datastore for even numbered machines.
variable "vsphere_network" {
  type = string
}

// vsphere server, defaults to localhost
variable "vsphere_server" {
  type = string
}

// the name of the virtual machine domain suffix. 
variable "vsphere_virtual_machine_domain" {
  type = string
}

// the folder you want the node to show up inside
variable "vsphere_virtual_machine_folder" {
  type = string
}

// vsphere virtual machine template that the virtual machine will be cloned from.
variable "vsphere_virtual_machine_template" {
  type = string
}

// vsphere login account.
variable "vsphere_username" {
  type = string
}

// vsphere account password.
variable "vsphere_password" {
  type = string
}

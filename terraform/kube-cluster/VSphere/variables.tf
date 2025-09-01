
// the azure region you require resources from.
variable "azure_region" {
  type = string
}

// the azure resource group name.
variable "azure_rg_name" {
  type = string
}

// the azure blob name you need to use.
variable "azure_blob_name" {
  type = string
}

// the azure storage account name.
variable "azure_storage_account_name" {
  type = string
}

// the branch  you are deploying from
variable "branch" {
  type = string
}

// team the noc should contact.
variable "nocpointofcontact" {
  type = string
}

// vsphere datacenter the virtual machine will be deployed to.
variable "vsphere_datacenter" {
  type = string
}

// vsphere datastore for even numbered machines.
variable "vsphere_datastore_0" {
  type = string
}

// vsphere datastore for odd numbered machines.
variable "vsphere_datastore_1" {
  type = string
}

// the vswitch path
variable "vsphere_distributed_virtual_switch" {
  type = string
}

// vsphere network for zauth
variable "vsphere_network_auth" {
  type = string
}

// vsphere network for cluster
variable "vsphere_network_cluster" {
  type = string
}

// vsphere network for mgmt and tools
variable "vsphere_network_mgmt" {
  type = string
}

// vsphere account password.
variable "vsphere_password" {
  type = string
}

// vsphere resource pool the virtual machine will be deployed to.
variable "vsphere_resource_pool" {
  type = string
}

// vsphere server, defaults to localhost
variable "vsphere_server" {
  type = string
}

// vsphere login account.
variable "vsphere_user" {
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

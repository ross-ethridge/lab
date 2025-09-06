// Packer Vars

variable "packer_password" {
  type      = string
  sensitive = true
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_folder" {
  type = string
}

variable "vsphere_host" {
  type = string
}

variable "vsphere_iso_url" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "vsphere_password" {
  type      = string
  sensitive = true
}

variable "vsphere_server" {
  type = string
}

variable "vsphere_username" {
  type      = string
  sensitive = true
}




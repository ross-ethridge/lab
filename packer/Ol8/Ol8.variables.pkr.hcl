// Packer Vars


variable "image_pass" {
  type = string
}

variable "iso_url_vsphere" {
  type = string
}

variable "vsphere_cluster" {
  type = string
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

variable "vsphere_network" {
  type = string
}

variable "vsphere_pass" {
  type      = string
  sensitive = true
}


variable "vsphere_server" {
  type = string
}

variable "vsphere_user" {
  type = string
}

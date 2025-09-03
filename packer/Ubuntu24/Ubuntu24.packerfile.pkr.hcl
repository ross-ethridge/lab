# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# source blocks are analogous to the "builders" in json templates. They are used
# in build blocks. A build block runs provisioners and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
packer {
  required_version = "~> 1"
  required_plugins {
    vsphere = {
      version = "~> 2"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

// Random packer password
locals {
  timestamp             = formatdate("MMDDhhmmss", timestamp())
  vsphere_image         = "pkrbuild"
  packer_username       = "packer"
  packer_password       = uuidv4()
  vsphere_guest_os_type = "ubuntu64Guest"
}


source "vsphere-iso" "ubuntu24" {
  vm_name             = local.vsphere_image
  username            = "ross.ethridge@washco-web.com"
  ssh_username        = local.packer_username
  host                = "esxi-01.washco-web.com"
  guest_os_type       = local.vsphere_guest_os_type
  CPUs                = 2
  RAM                 = 4096
  RAM_reserve_all     = true
  password            = var.vsphere_password
  vcenter_server      = var.vsphere_server
  ssh_password        = local.packer_password
  remove_cdrom        = true
  insecure_connection = true
  iso_paths           = [var.vsphere_iso_url]
  iso_checksum        = "none"
  convert_to_template = true
  datacenter          = var.vsphere_datacenter
  datastore           = var.vsphere_datastore
  folder              = var.vsphere_folder
  ssh_timeout         = "15m"
  http_port_min       = 1420
  http_port_max       = 1420
  # cd_files = [
  #     "cdrom/user-data",
  #     "cdrom/meta-data"
  #   ]
  # cd_label = "nocloud" # Or "cidata"

  # http_directory      = "./http"
  http_content = {
    "/user-data" = templatefile("${path.root}/templates/user-data.pkrtpl.hcl", {
      packer_password = local.packer_password
      host_name       = local.vsphere_image
    }),
    "/meta-data" = templatefile("${path.root}/templates/meta-data.pkrtpl.hcl", {
    })
  }

  boot_order = "disk,cdrom"
  boot_wait  = "5s"

  boot_command = [
    "<esc><esc><esc>",
    "e<wait>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del><del><del>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>",
    "<enter><f10><wait>"
  ]

  network_adapters {
    network_card = "vmxnet3"
  }

  disk_controller_type = ["lsilogic"]
  storage {
    disk_size             = 40000
    disk_thin_provisioned = false
  }

}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.vsphere-iso.ubuntu24"]

  provisioner "shell" {
    inline = ["ls /"]
  }

  provisioner "shell-local" {
    inline = ["echo packer_password is: ${local.packer_password}"]
  }
}
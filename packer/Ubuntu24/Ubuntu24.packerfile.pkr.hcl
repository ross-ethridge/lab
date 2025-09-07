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

// Locals
locals {
  timestamp             = formatdate("MMDDhhmmss", timestamp())
  vsphere_image         = "pkrbuild-${local.timestamp}"
  packer_username       = "packer"
  vsphere_guest_os_type = "ubuntu64Guest"
}

source "vsphere-iso" "ubuntu24" {
  vm_name             = local.vsphere_image
  ssh_username        = local.packer_username
  guest_os_type       = local.vsphere_guest_os_type
  username            = var.vsphere_username
  ssh_password        = var.packer_password
  host                = var.vsphere_host
  password            = var.vsphere_password
  vcenter_server      = var.vsphere_server
  datacenter          = var.vsphere_datacenter
  datastore           = var.vsphere_datastore
  folder              = var.vsphere_folder
  iso_paths           = [var.vsphere_iso_url]
  CPUs                = 2
  RAM                 = 4096
  RAM_reserve_all     = true
  remove_cdrom        = true
  insecure_connection = true
  iso_checksum        = "none"
  convert_to_template = true
  ssh_timeout         = "30m"
  boot_order          = "cdrom,disk"
  boot_wait           = "5s"

  // Run autoinstall from the cdrom files
  cd_files = ["cdrom/meta-data", "cdrom/user-data"]
  cd_label = "cidata"


  // This boot command disables network because somtimes its not available and you need to install from iso
  // if you want to enable network, remove 'network-config=disabled'
  // Its added back inside user-data so it works on reboot.
  boot_command = [
    "c",
    "<wait3s>",
    "linux /casper/vmlinuz quiet network-config=disabled autoinstall ds=nocloud;",
    "<enter><wait3s>",
    "initrd /casper/initrd",
    "<enter><wait3s>",
    "boot",
    "<enter>"
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
    inline = [
      "echo ${var.packer_password} | sudo -S rm -f /etc/cloud/cloud.cfg.d/*",
      "echo ${var.packer_password} | sudo -S rm -f /etc/cloud/ds-indentity.cfg",
      "echo ${var.packer_password} | sudo -S rm -f /etc/cloud/cloud-init.disabled",
      "echo 'disable_vmware_customization: true' | echo ${var.packer_password} | sudo -S tee /etc/cloud/cloud.cfg.d/99-vmware-disable.cfg"
    ]
  }
}
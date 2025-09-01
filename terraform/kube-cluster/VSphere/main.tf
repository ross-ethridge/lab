terraform {
#  backend "local" {}
  backend "azurerm" {
    resource_group_name  = var.resource_group_name
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = "kube_cluster.terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "lab" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore_1" {
  name          = var.vsphere_datastore_1
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "kubernetes" {
  name                            = var.vsphere_network_mgmt
  datacenter_id                   = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.tools_vswitch.id
}

data "vsphere_virtual_machine" "vm_template" {
  name          = var.vsphere_virtual_machine_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "local_file" "build_key_pub" {
  filename = "~/.ssh/tf_id_rsa.pub"
}

data "template_file" "userdata" {
  vars = {
    build_key_pub = data.local_file.build_key_pub.content
  }
  template = file("${path.module}/templates/user-data.tpl")
}

data "template_file" "metadata" {
  template = file("${path.module}/templates/meta-data.tpl")
}


# KubeMaster VM
resource "vsphere_virtual_machine" "kubemaster" {
  count            = 1
  name             = format("kubemaster-%02d", count.index) + ".${var.vsphere_virtual_machine_domain}"
  datastore_id     = data.vsphere_datastore.datastore_1.id
  folder           = var.vsphere_virtual_machine_folder
  num_cpus = data.vsphere_virtual_machine.template.num_cpus
  memory   = data.vsphere_virtual_machine.template.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.vault.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
    customize {
      linux_options {
        host_name = format("kubemaster-%02d", count.index)
        domain    = var.vsphere_virtual_machine_domain
      }
      network_interface {}
    }
  }

  extra_config = {
    "guestinfo.userdata"          = base64encode(data.template_file.userdata.rendered)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(data.template_file.metadata.rendered)
    "guestinfo.metadata.encoding" = "base64"
  }

  # tags = [
  # 
  # ]

}

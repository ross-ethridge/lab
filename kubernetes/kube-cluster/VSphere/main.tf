terraform {
  backend "local" {}
  # backend "azurerm" {
  #   resource_group_name = "washco-lab"
  #   storage_account_name = "washco-lab"
  #   container_name = "washco-lab"
  #   key = "kube_cluster.terraform.tfstate"
  # }
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
  user                 = var.vsphere_username
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "lab" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "lab" {
  name          = "Lab"
  datacenter_id = data.vsphere_datacenter.lab.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.lab.id
}

data "vsphere_network" "vm_network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.lab.id
}

data "vsphere_virtual_machine" "vm_template" {
  name          = var.vsphere_virtual_machine_template
  datacenter_id = data.vsphere_datacenter.lab.id
}

data "local_file" "build_key_pub" {
  filename = "build-keys/packer-build-key.pub"
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
  name             = "kubemaster-0${count.index}.${var.vsphere_virtual_machine_domain}"
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vsphere_virtual_machine_folder
  num_cpus         = data.vsphere_virtual_machine.vm_template.num_cpus
  memory           = data.vsphere_virtual_machine.vm_template.memory
  guest_id         = data.vsphere_virtual_machine.vm_template.guest_id
  resource_pool_id = data.vsphere_compute_cluster.lab.resource_pool_id

  scsi_type = data.vsphere_virtual_machine.vm_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.vm_network.id
    adapter_type = data.vsphere_virtual_machine.vm_template.network_interface_types[0]
  }

  disk {
    thin_provisioned = data.vsphere_virtual_machine.vm_template.disks.0.thin_provisioned
    label            = "disk0"
    size             = data.vsphere_virtual_machine.vm_template.disks.0.size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
    customize {
      linux_options {
        host_name = "kubemaster-0${count.index}"
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
  

}

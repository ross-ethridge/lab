terraform {
  backend "local" {}
  # backend "s3" {
  #   bucket  = "ross-lab-tfstate"
  #   key     = "kube/cluster.terraform.tfstate"
  #   region  = "us-east-2"
  #   encrypt = true
  #}

  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  remote {
    name    = "lxd"
    address = "https://lxd.chingadero.com:8443"
    default = true

    // server: lxc config trust add --name "terraform-token"
    // client: export TF_VAR_lxd_token="tokenValue..."
    token = var.lxd_token
  }
}


// RKE1 VM Instance
resource "lxd_instance" "rke1" {
  depends_on = [
    lxd_storage_pool.rke1,
    lxd_profile.rke1
  ]
  profiles = ["rke1"]
  type     = "virtual-machine"
  name     = "rke1"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = lxd_storage_pool.rke1.name
      size = "100GiB"
      path = "/"
    }
  }

  config = {
    "boot.autostart" = true
    // Read user-data from file:
    // "user.user-data" = file("${path.module}/cloud-init.yaml")

    // Or embed directly:
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: rke1
      fqdn: rke1.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - wget
        - gnupg
        - lsb-release
        - nfs-common
      
      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzXWSD4lP+DwrWDm43NzxmhloNg/XBGCIOeexWl8xN85OXy3D5zGirDWLL6VuRqYUEXycvWt5p+2TvfJ3Wj1tD9GfcAuJOiuEXDfL7ktFfhqdGri3sbI0V1KVbMdJ5UOfwa3LIROl6EHedMq2Z9pf9Yfj8hlNSBDkMKUMkJlVjmIk4LNIbDnQK2gHrS37R+KS63Q7Eu/VUoP+AdOiyocnPCtUEekDt3S28vGoXdqnE1FE6LO+K1y3o00yyDa+AIHsBDWrN9dD8AJuSKx9dRymPtMuONzEWULFp4Fy094wEXsgkBH8V0bSTGeEyJ2HxD+9f51OcY+cQSvR3roZd8zx7eLCmXZx/jjFGjIMTLTMZhamgRsrE6vURYU5X/W7Lh5IjgoIHqxnsFO44LeoBwPaLvkgoQBEScNpRk4ijzpfT3yxRa4x0CPYAUbW9CgQLpqPNxOhQd+akOutVCkwAa6TEw++apfc/TdPxSNLSX5CVqeirmTSKqHhURsbylFXjMaE= ross@notebook"

      runcmd:
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - mkdir /data

    EOF
  }
}


// Output Ip Addresses
output "rke1" {
  value = {
    "${lxd_instance.rke1.name}" = "${lxd_instance.rke1.ipv4_address}"
  }
}

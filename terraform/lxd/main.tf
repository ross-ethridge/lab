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
    name    = "lootavelli"
    address = "https://lootavelli.washco-web.com:8443"
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6V3imtW9VghfTuR7tZdDDj0baqYgUmRJZz2tWxiSmAAXCRTK6LEXHz1ZrBRhAwA5bNYwaMd8rGguKJrMKUsx7fpCMwnQKRqfoh1qiAtfxid2IGBPqi8xBlL1xqYyNt1TMD+1GUKd1qltunz0nM9KIddgu4bQWcC0o/WAbJ4Cz1lq+3GiEaWra/HUDQBPgC4ccAv/pTz609JRiHpHO0LHfqECKiSK2pQz2OvMhY9zNZErXUWFcH/GNN/PJQfj3GgEhuiRYxVynMbaxgp+5fvOFrpMb5BWOfjL8fg6N3vizAQWvnoDTsBTKstvY0QMsA0B8RtUAOaF96nNlbF3mwLI9 rossethridge@lootavelli.washco-web.com"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - mkdir /data

      write_files:
        - path: /etc/hosts
          append: true
          content: |
            127.0.1.1 rancher.washco-web.com
    EOF
  }
}


// Output Ip Addresses
output "rke1" {
  value = {
    "${lxd_instance.rke1.name}" = "${lxd_instance.rke1.ipv4_address}"
  }
}

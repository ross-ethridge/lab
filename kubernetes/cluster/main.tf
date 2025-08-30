terraform {
  backend "local" {}
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  remote {
    name    = "microcloud-01"
    address = "https://192.168.2.2:8443/"
    default = true

    // export TF_VAR_lxd_token='token value...'
    token = var.lxd_token
  }
}


// Storage pool for instance
resource "lxd_storage_pool" "kubemaster_pool" {
  name   = "kubemaster-pool"
  driver = "zfs"
}

// LXD VM Instance
resource "lxd_instance" "kubemaster" {
  depends_on = [lxd_storage_pool.kubemaster_pool]
  type       = "virtual-machine"
  name       = "kubemaster"
  image      = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = lxd_storage_pool.kubemaster_pool.name
      size = "20GiB"
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
      packages:
        - build-essential
        - openssh-server

      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1wrYOvWiCDf7hLfN/rIq1sPyS25bLKa0dCHGEvcO/banPy7ooHCqVJgHeQNUh8gkBKSGzYoVObbrt6AIaVYndRPQhGJ5BvR1sKTxt/NOnKm2Ya0HwEK1dYX3weNzCQxq0MA8dX0HybjABRikd1+4845FjVqsWEL6hGZSS3vPFl9J/f4CO0qMk5DF3O4wQozppSaoWJtWpGsl0stVQqeTGw9f9QJ0MxQvlvNPuoFazRbvdPNjfCjnd8AEBZRJBBUEmwRhHPgBAyr0c9Bxh88yYaFXgST81/mHSjC8SAHJXQf06AQv3dxLzCPduQJa297qE0p4rE7cABGalgo69pE/ rethridge@rethridge-pc'
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCshYoGv5o0T0Z8vFQvwu1vFSlWZOZEuH40FVUHH0gg1jiQhQ2JP1Sjydnj2K9ejzrzk7eJyTjTYceI5BYBj6ey02VoY1PKBYjgbYb1U/JVpJ5fP9OYzn1l3plySLW7pTB7UTE5+pBToB5tVr/D2GDnGo138+eAG89gaFZbwyczTlxcg7J+cnd1zZymSOOUUSqOoSNWtTf4lcfmOKf5sM9OGBMQPS2CWUfI39jNEOsC+BmcqLcskdwuEGAEdMxSvIvo9Otrww9wBaG3w2cvTnlrAyAGURI0w+Nt1+AOgMwoSMZ5RqjEcnxRWyGwuHI7AubqLTjq2ZSjejby8bqu8F7t rossethridge@microcloud-01'
      
      runcmd:
        - systemctl emable sshd --now

      EOF
  }

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

}


// Storage pool for instance
resource "lxd_storage_pool" "kubeworker_pool" {
  count  = 3
  name   = "kubeworker${count.index}-pool"
  driver = "zfs"
}

// LXD VM Instance
resource "lxd_instance" "kubeworker" {
  depends_on = [lxd_storage_pool.kubeworker_pool]
  count      = 3
  type       = "virtual-machine"
  name       = "kubeworker${count.index}"
  image      = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = lxd_storage_pool.kubeworker_pool[count.index].name
      size = "20GiB"
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
      packages:
        - build-essential
        - openssh-server

      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1wrYOvWiCDf7hLfN/rIq1sPyS25bLKa0dCHGEvcO/banPy7ooHCqVJgHeQNUh8gkBKSGzYoVObbrt6AIaVYndRPQhGJ5BvR1sKTxt/NOnKm2Ya0HwEK1dYX3weNzCQxq0MA8dX0HybjABRikd1+4845FjVqsWEL6hGZSS3vPFl9J/f4CO0qMk5DF3O4wQozppSaoWJtWpGsl0stVQqeTGw9f9QJ0MxQvlvNPuoFazRbvdPNjfCjnd8AEBZRJBBUEmwRhHPgBAyr0c9Bxh88yYaFXgST81/mHSjC8SAHJXQf06AQv3dxLzCPduQJa297qE0p4rE7cABGalgo69pE/ rethridge@rethridge-pc'
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCshYoGv5o0T0Z8vFQvwu1vFSlWZOZEuH40FVUHH0gg1jiQhQ2JP1Sjydnj2K9ejzrzk7eJyTjTYceI5BYBj6ey02VoY1PKBYjgbYb1U/JVpJ5fP9OYzn1l3plySLW7pTB7UTE5+pBToB5tVr/D2GDnGo138+eAG89gaFZbwyczTlxcg7J+cnd1zZymSOOUUSqOoSNWtTf4lcfmOKf5sM9OGBMQPS2CWUfI39jNEOsC+BmcqLcskdwuEGAEdMxSvIvo9Otrww9wBaG3w2cvTnlrAyAGURI0w+Nt1+AOgMwoSMZ5RqjEcnxRWyGwuHI7AubqLTjq2ZSjejby8bqu8F7t rossethridge@microcloud-01'

      runcmd:
        - systemctl emable sshd --now

      EOF
  }

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

}



output "kubemaster_ip_address" {
  value = lxd_instance.kubemaster.ipv4_address
}
output "kubeworker0_ip_address" {
  value = lxd_instance.kubeworker[0].ipv4_address
}
output "kubeworker1_ip_address" {
  value = lxd_instance.kubeworker[1].ipv4_address
}
output "kubeworker2_ip_address" {
  value = lxd_instance.kubeworker[2].ipv4_address
}

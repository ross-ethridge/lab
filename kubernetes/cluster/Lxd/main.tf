terraform {
  backend "local" {}
  # backend "s3" {
  #   bucket  = "ross-lab-tfstate"
  #   key     = "kube/cluster.terraform.tfstate"
  #   region  = "us-east-2"
  #   encrypt = true
  # }

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
    address = "https://lootavelli.washco-web.com:8443/"
    default = true

    // server: lxc config trust add --name "terraform-token"
    // client: export TF_VAR_lxd_token="tokenValue..."
    token = var.lxd_token
  }
}


// KubeMaster1 VM Instance
resource "lxd_instance" "kubemaster1" {
  depends_on = [
    lxd_storage_pool.kubemaster_pool,
    lxd_profile.kubemaster1
  ]
  profiles = ["kubemaster1"]
  type     = "virtual-machine"
  name     = "kubemaster1"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubemaster1-pool"
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
      hostname: kubemaster1
      fqdn: kubemaster1.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}


// KubeMaster2 VM Instance
resource "lxd_instance" "kubemaster2" {
  depends_on = [
    lxd_storage_pool.kubemaster_pool,
    lxd_profile.kubemaster2
  ]
  profiles = ["kubemaster2"]
  type     = "virtual-machine"
  name     = "kubemaster2"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubemaster2-pool"
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
      hostname: kubemaster2
      fqdn: kubemaster2.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}

// KubeMaster3 VM Instance
resource "lxd_instance" "kubemaster3" {
  depends_on = [
    lxd_storage_pool.kubemaster_pool,
    lxd_profile.kubemaster3
  ]
  profiles = ["kubemaster3"]
  type     = "virtual-machine"
  name     = "kubemaster3"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubemaster3-pool"
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
      hostname: kubemaster3
      fqdn: kubemaster3.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}

// KubeWorker1
resource "lxd_instance" "kubeworker1" {
  depends_on = [
    lxd_storage_pool.kubeworker_pool,
    lxd_profile.kubeworker1
  ]
  profiles = ["kubeworker1"]
  type     = "virtual-machine"
  name     = "kubeworker1"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubeworker1-pool"
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
      hostname: kubeworker1
      fqdn: kubeworker1.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}


// KubeWorker2
resource "lxd_instance" "kubeworker2" {
  depends_on = [
    lxd_storage_pool.kubeworker_pool,
    lxd_profile.kubeworker2
  ]
  profiles = ["kubeworker2"]
  type     = "virtual-machine"
  name     = "kubeworker2"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubeworker2-pool"
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
      hostname: kubeworker2
      fqdn: kubeworker2.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}


// KubeWorker3
resource "lxd_instance" "kubeworker3" {
  depends_on = [
    lxd_storage_pool.kubeworker_pool,
    lxd_profile.kubeworker3
  ]
  profiles = ["kubeworker3"]
  type     = "virtual-machine"
  name     = "kubeworker3"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "kubeworker3-pool"
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
      hostname: kubeworker2
      fqdn: kubeworker2.washco-web.com
      prefer_fqdn_over_hostname: true
      create_hostname_file: true
      package_update: true
      packages_upgrade: true
      reboot: auto
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY6YL4KJSqaIpaV+E9h7cImLY0J7RRjjaFv+HXpLvbov4obhxwanIDjT5neqyFRi1iLtVg0b+N4k8/cEGEwrmb6jbmOOx7HYnVZ+tpvmXe9DAm6Xg/GtDM5vwzdBoa05ZIAbY/JUu0C/KDiqbjD784w9vr6eGsXnL++kW79FxgyEoTZPkJiLTemz8BJI4xgsbvbWLGE+b0aNOGX7M2xY8kXjfIVmzohngzA/W6W5o8U9giX7U0z0lsuWvFFM73eCfAv6zGjNVNxUMiMMNeQABmaYVT0AvVNBgNEhP0025gIZHu0FLf/W/jEzAgyWAmE8wu21CKRHAp1QsXZ9FxegcF rossethridge@lootavelli"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - apt update
        - apt install -y docker docker-compose containerd.io
        - apt-mark hold docker docker-compose containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable --now docker
        - mkdir /data
      EOF
  }
}



// Output Ip Addresses
output "KubeMaster1" {
  value = {
    "${lxd_instance.kubemaster1.name}" = "${lxd_instance.kubemaster1.ipv4_address}"
  }
}

output "KubeMaster2" {
  value = {
    "${lxd_instance.kubemaster2.name}" = "${lxd_instance.kubemaster2.ipv4_address}"
  }
}

output "KubeMaster3" {
  value = {
    "${lxd_instance.kubemaster3.name}" = "${lxd_instance.kubemaster3.ipv4_address}"
  }
}

output "KubeWorker1" {
  value = {
    "${lxd_instance.kubeworker1.name}" = "${lxd_instance.kubeworker1.ipv4_address}"
  }
}

output "KubeWorker2" {
  value = {
    "${lxd_instance.kubeworker2.name}" = "${lxd_instance.kubeworker2.ipv4_address}"
  }
}

output "KubeWorker3" {
  value = {
    "${lxd_instance.kubeworker3.name}" = "${lxd_instance.kubeworker3.ipv4_address}"
  }
}

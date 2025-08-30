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

    // server: lxc config trust add --name "terraform-token"
    // client: export TF_VAR_lxd_token="tokenValue..."
    token = var.lxd_token
  }
}


// Storage pool for kubemaster instance
resource "lxd_storage_pool" "kubemaster_pool" {
  name   = "kubemaster-pool"
  driver = "zfs"
}

// KubeMaster VM Instance
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
      package_update: true
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - wget
        - gnupg
        - lsb-release
      
      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1wrYOvWiCDf7hLfN/rIq1sPyS25bLKa0dCHGEvcO/banPy7ooHCqVJgHeQNUh8gkBKSGzYoVObbrt6AIaVYndRPQhGJ5BvR1sKTxt/NOnKm2Ya0HwEK1dYX3weNzCQxq0MA8dX0HybjABRikd1+4845FjVqsWEL6hGZSS3vPFl9J/f4CO0qMk5DF3O4wQozppSaoWJtWpGsl0stVQqeTGw9f9QJ0MxQvlvNPuoFazRbvdPNjfCjnd8AEBZRJBBUEmwRhHPgBAyr0c9Bxh88yYaFXgST81/mHSjC8SAHJXQf06AQv3dxLzCPduQJa297qE0p4rE7cABGalgo69pE/ rethridge@rethridge-pc"
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCshYoGv5o0T0Z8vFQvwu1vFSlWZOZEuH40FVUHH0gg1jiQhQ2JP1Sjydnj2K9ejzrzk7eJyTjTYceI5BYBj6ey02VoY1PKBYjgbYb1U/JVpJ5fP9OYzn1l3plySLW7pTB7UTE5+pBToB5tVr/D2GDnGo138+eAG89gaFZbwyczTlxcg7J+cnd1zZymSOOUUSqOoSNWtTf4lcfmOKf5sM9OGBMQPS2CWUfI39jNEOsC+BmcqLcskdwuEGAEdMxSvIvo9Otrww9wBaG3w2cvTnlrAyAGURI0w+Nt1+AOgMwoSMZ5RqjEcnxRWyGwuHI7AubqLTjq2ZSjejby8bqu8F7t rossethridge@microcloud-01"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/{etcd,etcdctl} /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - sysctl -w net.ipv4.ip_forward=1
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - sysctl -p
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service

      EOF
  }

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

}


// Storage pool for kubeworker instance(s)
resource "lxd_storage_pool" "kubeworker_pool" {
  count  = 3
  name   = "kubeworker${count.index}-pool"
  driver = "zfs"
}

// KubeWorker VM Instance(s)
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
      package_update: true
      packages:
        - apt-transport-https
        - ca-certificates
        - curl
        - wget
        - gnupg
        - lsb-release
      
      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1wrYOvWiCDf7hLfN/rIq1sPyS25bLKa0dCHGEvcO/banPy7ooHCqVJgHeQNUh8gkBKSGzYoVObbrt6AIaVYndRPQhGJ5BvR1sKTxt/NOnKm2Ya0HwEK1dYX3weNzCQxq0MA8dX0HybjABRikd1+4845FjVqsWEL6hGZSS3vPFl9J/f4CO0qMk5DF3O4wQozppSaoWJtWpGsl0stVQqeTGw9f9QJ0MxQvlvNPuoFazRbvdPNjfCjnd8AEBZRJBBUEmwRhHPgBAyr0c9Bxh88yYaFXgST81/mHSjC8SAHJXQf06AQv3dxLzCPduQJa297qE0p4rE7cABGalgo69pE/ rethridge@rethridge-pc"
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCshYoGv5o0T0Z8vFQvwu1vFSlWZOZEuH40FVUHH0gg1jiQhQ2JP1Sjydnj2K9ejzrzk7eJyTjTYceI5BYBj6ey02VoY1PKBYjgbYb1U/JVpJ5fP9OYzn1l3plySLW7pTB7UTE5+pBToB5tVr/D2GDnGo138+eAG89gaFZbwyczTlxcg7J+cnd1zZymSOOUUSqOoSNWtTf4lcfmOKf5sM9OGBMQPS2CWUfI39jNEOsC+BmcqLcskdwuEGAEdMxSvIvo9Otrww9wBaG3w2cvTnlrAyAGURI0w+Nt1+AOgMwoSMZ5RqjEcnxRWyGwuHI7AubqLTjq2ZSjejby8bqu8F7t rossethridge@microcloud-01"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/etcdctl /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - sysctl -w net.ipv4.ip_forward=1
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - sysctl -p
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service

      EOF
  }

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

}

// Output Ip Addresses

output "kubemaster_ip" {
  value = lxd_instance.kubemaster.ipv4_address
}

output "kubeworker_ips" {
  value = {
    for instance in lxd_instance.kubeworker :
    instance.name => instance.ipv4_address
  }
}

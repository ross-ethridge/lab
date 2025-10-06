terraform {
  #backend "local" {}
  backend "s3" {
    bucket  = "ross-lab-tfstate"
    key     = "kube/cluster.terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }

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


// KubeMaster VM Instance
resource "lxd_instance" "kubemaster" {
  depends_on = [
    lxd_storage_pool.kubemaster_pool,
    lxd_profile.kubemaster
  ]
  profiles = ["kubemaster"]
  type     = "virtual-machine"
  name     = "kubemaster"
  image    = "ubuntu:24.04"

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = lxd_storage_pool.kubemaster_pool.name
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
      hostname: kubemaster
      fqdn: kubemaster.washco-web.com
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqdFl8zRCZRJT7X/zlUeun5muUHAMXA122GAjh94RwhH4fv0t1kTmDatrDs6oLLiYsDMU0u1BOiWPZ195D7Kbf1U/eBUVaB6BqmuqkzEW8FZos7OkuTzsxm0AaI+7mAxfGJsFhDzNQOnKiZO8Emc5VlP3zMFxZOTfsBLwWraEDfiSjQe9YXv1ukQN6jVp6pTc38G2BGmGp+1Orrans5ewSuHjpg6ROHbjhonn3HN8fc6M8rxg6M7mnyReZRuQ5nr/OibHmk+hEUI0EPB++nUtF+LYTCw1JR2rhYfJ3LzfFCn/iQhPYt2ploonAXj8ZUh66Bkyk74gzT/h4gzZB6fSj UbuntuDesktopKey"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/etcdctl /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service
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
      hostname: kubeworker1
      fqdn: kubeworker1.washco-web.com
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqdFl8zRCZRJT7X/zlUeun5muUHAMXA122GAjh94RwhH4fv0t1kTmDatrDs6oLLiYsDMU0u1BOiWPZ195D7Kbf1U/eBUVaB6BqmuqkzEW8FZos7OkuTzsxm0AaI+7mAxfGJsFhDzNQOnKiZO8Emc5VlP3zMFxZOTfsBLwWraEDfiSjQe9YXv1ukQN6jVp6pTc38G2BGmGp+1Orrans5ewSuHjpg6ROHbjhonn3HN8fc6M8rxg6M7mnyReZRuQ5nr/OibHmk+hEUI0EPB++nUtF+LYTCw1JR2rhYfJ3LzfFCn/iQhPYt2ploonAXj8ZUh66Bkyk74gzT/h4gzZB6fSj UbuntuDesktopKey"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/etcdctl /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service
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
      hostname: kubeworker2
      fqdn: kubeworker2.washco-web.com
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqdFl8zRCZRJT7X/zlUeun5muUHAMXA122GAjh94RwhH4fv0t1kTmDatrDs6oLLiYsDMU0u1BOiWPZ195D7Kbf1U/eBUVaB6BqmuqkzEW8FZos7OkuTzsxm0AaI+7mAxfGJsFhDzNQOnKiZO8Emc5VlP3zMFxZOTfsBLwWraEDfiSjQe9YXv1ukQN6jVp6pTc38G2BGmGp+1Orrans5ewSuHjpg6ROHbjhonn3HN8fc6M8rxg6M7mnyReZRuQ5nr/OibHmk+hEUI0EPB++nUtF+LYTCw1JR2rhYfJ3LzfFCn/iQhPYt2ploonAXj8ZUh66Bkyk74gzT/h4gzZB6fSj UbuntuDesktopKey"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/etcdctl /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service
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
      hostname: kubeworker3
      fqdn: kubeworker3.washco-web.com
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
            - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqdFl8zRCZRJT7X/zlUeun5muUHAMXA122GAjh94RwhH4fv0t1kTmDatrDs6oLLiYsDMU0u1BOiWPZ195D7Kbf1U/eBUVaB6BqmuqkzEW8FZos7OkuTzsxm0AaI+7mAxfGJsFhDzNQOnKiZO8Emc5VlP3zMFxZOTfsBLwWraEDfiSjQe9YXv1ukQN6jVp6pTc38G2BGmGp+1Orrans5ewSuHjpg6ROHbjhonn3HN8fc6M8rxg6M7mnyReZRuQ5nr/OibHmk+hEUI0EPB++nUtF+LYTCw1JR2rhYfJ3LzfFCn/iQhPYt2ploonAXj8ZUh66Bkyk74gzT/h4gzZB6fSj UbuntuDesktopKey"

      runcmd:
        - mkdir -p /etc/apt/keyrings
        - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        - bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --prefix=/usr/local
        - cp /usr/local/share/oh-my-bash/bashrc ~rossethridge/.bashrc
        - cp /usr/local/share/oh-my-bash/bashrc ~/.bashrc
        - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
        - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
        - wget https://github.com/etcd-io/etcd/releases/download/v3.6.4/etcd-v3.6.4-linux-amd64.tar.gz
        - tar -xvzf etcd-v3.6.4-linux-amd64.tar.gz
        - cp etcd-v3.6.4-linux-amd64/etcdctl /usr/local/bin/
        - apt update
        - apt install -y kubelet kubeadm kubectl containerd.io
        - containerd config default | sudo tee /etc/containerd/config.toml
        - sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
        - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        - apt-mark hold kubelet kubeadm kubectl containerd.io
        - modprobe br_netfilter
        - modprobe bridge
        - echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
        - echo "net.bridge.bridge-nf-call-iptables = 1" | tee -a /etc/sysctl.conf
        - sysctl -p /etc/sysctl.conf
        - echo "br_netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
        - systemctl enable containerd
        - systemctl enable kubelet
        - systemctl restart containerd.service
        - systemctl restart kubelet.service
        - mkdir /data
      EOF
  }
}



// Output Ip Addresses
output "KubeMaster" {
  value = {
    "${lxd_instance.kubemaster.name}" = "${lxd_instance.kubemaster.ipv4_address}"
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

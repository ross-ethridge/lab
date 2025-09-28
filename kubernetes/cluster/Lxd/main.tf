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
    address = "https://localhost:8443/"
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
  profiles   = ["host-profile"]
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
  profiles   = ["host-profile"]
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

  limits = {
    cpu    = 2
    memory = "4GiB"
  }

}

// Output Ip Addresses

output "ControlPlane" {
  value = {
    "${lxd_instance.kubemaster.name}.lxd" = "${lxd_instance.kubemaster.ipv4_address}"
  }
}

output "Workers" {
  value = {
    for instance in lxd_instance.kubeworker :
    "${instance.name}.lxd" => instance.ipv4_address
  }
}

// Profile for KubeMaster
resource "lxd_profile" "kubemaster" {
  name = "kubemaster"
  depends_on = [
    lxd_storage_pool.kubemaster_pool
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "kubemaster-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "macvlan"
      parent  = "enp56s0"
    }
  }

  config = {
    "limits.cpu"          = 2
    "limits.memory"       = "4GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          addresses:
            - "${var.ip_address["lab"].kubemaster}"
          nameservers:
            addresses:
              - 1.1.1.1
              - 192.168.2.1
          routes:
            - to: 0.0.0.0/0
              via: 192.168.2.1
    EOT
  }
}



// Profile for KubeWorker1
resource "lxd_profile" "kubeworker1" {
  name = "kubeworker1"
  depends_on = [
    lxd_storage_pool.kubeworker_pool
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "kubeworker1-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "macvlan"
      parent  = "enp56s0"
    }
  }

  config = {
    "limits.cpu"          = 2
    "limits.memory"       = "4GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          addresses:
            - "${var.ip_address["lab"].kubeworker1}"
          nameservers:
            addresses:
              - 1.1.1.1
              - 192.168.2.1
          routes:
            - to: 0.0.0.0/0
              via: 192.168.2.1
    EOT
  }
}


// Profile for KubeWorker2
resource "lxd_profile" "kubeworker2" {
  name = "kubeworker2"
  depends_on = [
    lxd_storage_pool.kubeworker_pool
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "kubeworker2-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "macvlan"
      parent  = "enp56s0"
    }
  }

  config = {
    "limits.cpu"          = 2
    "limits.memory"       = "4GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          addresses:
            - "${var.ip_address["lab"].kubeworker2}"
          nameservers:
            addresses:
              - 1.1.1.1
              - 192.168.2.1
          routes:
            - to: 0.0.0.0/0
              via: 192.168.2.1
    EOT
  }
}


// Profile for KubeWorker3
resource "lxd_profile" "kubeworker3" {
  name = "kubeworker3"
  depends_on = [
    lxd_storage_pool.kubeworker_pool
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "kubeworker3-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "macvlan"
      parent  = "enp56s0"
    }
  }

  config = {
    "limits.cpu"          = 2
    "limits.memory"       = "4GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          addresses:
            - "${var.ip_address["lab"].kubeworker3}"
          nameservers:
            addresses:
              - 1.1.1.1
              - 192.168.2.1
          routes:
            - to: 0.0.0.0/0
              via: 192.168.2.1
    EOT
  }
}

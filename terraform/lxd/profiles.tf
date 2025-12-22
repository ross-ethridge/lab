// Profile for rke1
resource "lxd_profile" "rke1" {
  name = "rke1"
  depends_on = [
    lxd_storage_pool.rke1
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "rke1-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "bridged"
      parent  = "lxdbr0"
    }
  }

  config = {
    "limits.cpu"          = 4
    "limits.memory"       = "8GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          dhcp4: true
          dhcp6: false
          nameservers:
            addresses:
              - 1.1.1.1
              - 8.8.8.8
    EOT
  }
}


// Profile for rke2
resource "lxd_profile" "rke2" {
  name = "rke2"
  depends_on = [
    lxd_storage_pool.rke2
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "rke2-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "bridged"
      parent  = "lxdbr0"
    }
  }

  config = {
    "limits.cpu"          = 4
    "limits.memory"       = "8GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          dhcp4: true
          dhcp6: false
          nameservers:
            addresses:
              - 1.1.1.1
              - 8.8.8.8
    EOT
  }
}



// Profile for rke3
resource "lxd_profile" "rke3" {
  name = "rke3"
  depends_on = [
    lxd_storage_pool.rke3
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "rke3-pool"
      path = "/"
      size = "100GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "bridged"
      parent  = "lxdbr0"
    }
  }

  config = {
    "limits.cpu"          = 4
    "limits.memory"       = "8GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          dhcp4: true
          dhcp6: false
          nameservers:
            addresses:
              - 1.1.1.1
              - 8.8.8.8
    EOT
  }
}

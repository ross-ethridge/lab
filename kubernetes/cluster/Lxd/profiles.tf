// Profile for KubeMaster
resource "lxd_profile" "rke1" {
  name = "rke1"
  depends_on = [
    lxd_storage_pool.rke1
  ]
  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "kubemaster-pool"
      path = "/"
      size = "50GiB"
    }
  }

  device {
    type = "nic"
    name = "enp5s0"
    properties = {
      nictype = "macvlan"
      parent  = "enp108s0"
    }
  }

  config = {
    "limits.cpu"          = 4
    "limits.memory"       = "4GiB"
    "user.network-config" = <<-EOT
      version: 2
      ethernets:
        enp5s0:
          addresses:
            - "${var.ip_address["lab"].rke1}"
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

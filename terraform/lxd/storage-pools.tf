// Storage pool for Rke1 Instance
resource "lxd_storage_pool" "rke1" {
  name        = "rke1-pool"
  driver      = "zfs"
  description = "Storage pool for rke1"
  config = {
    size = "100GiB"
  }
}

// Storage pool for Rke2 Instance
resource "lxd_storage_pool" "rke2" {
  name        = "rke2-pool"
  driver      = "zfs"
  description = "Storage pool for rke2"
  config = {
    size = "100GiB"
  }
}

// Storage pool for Rke3 Instance
resource "lxd_storage_pool" "rke3" {
  name        = "rke3-pool"
  driver      = "zfs"
  description = "Storage pool for rke3"
  config = {
    size = "100GiB"
  }
}

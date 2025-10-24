// Storage pool for KubeMaster Instance
resource "lxd_storage_pool" "rke1" {
  name        = "rke1-pool"
  driver      = "zfs"
  description = "Storage pool for rke1"
  config = {
    size = "50GiB"
  }
}
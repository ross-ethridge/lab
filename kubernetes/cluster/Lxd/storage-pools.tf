// Storage pool for KubeMaster Instance
resource "lxd_storage_pool" "kubemaster_pool" {
  name        = "kubemaster-pool"
  driver      = "zfs"
  description = "Storage pool for KubeMaster"
  config = {
    size = "100GiB"
  }
}

// Storage pool for Kubeworker Instances
resource "lxd_storage_pool" "kubeworker_pool" {
  count       = 3
  name        = "kubeworker${count.index + 1}-pool"
  driver      = "zfs"
  description = "Storage pool for KubeWorker${count.index + 1}"
  config = {
    size = "100GiB"
  }
}

// Storage pool for mealie
resource "lxd_storage_pool" "mealie" {
  name        = "mealie"
  driver      = "zfs"
  description = "Storage pool for mealie"
  config = {
    size = "20GiB"
  }
}

// Storage pool for openweb-ui
resource "lxd_storage_pool" "openweb" {
  name        = "openweb"
  driver      = "zfs"
  description = "Storage pool for openweb-ui"
  config = {
    size = "100GiB"
  }
}
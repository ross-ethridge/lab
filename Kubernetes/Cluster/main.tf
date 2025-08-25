terraform {
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
    name    = "my-pc"
    address = "https://192.168.2.2:8443/"
    default = true
    
    # export TF_VAR_lxd_token='token value...'
    token   = var.lxd_token
  }
}


resource "lxd_instance" "kube_master" {
  count = 1
  type  = "virtual-machine"
  name  = "kubemaster${count.index}"
  image = "ubuntu:24.04"

  config = {
    "boot.autostart" = true
    # Read user-data from file:
    # "user.user-data" = file("${path.module}/cloud-init.yaml")

    # Or embed directly:
    "user.user-data" = <<-EOF
      #cloud-config
      packages:
        - nginx
      users:
        - name: rossethridge
          groups: sudo,adm
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          shell: /bin/bash
          ssh_authorized_keys:
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN1wrYOvWiCDf7hLfN/rIq1sPyS25bLKa0dCHGEvcO/banPy7ooHCqVJgHeQNUh8gkBKSGzYoVObbrt6AIaVYndRPQhGJ5BvR1sKTxt/NOnKm2Ya0HwEK1dYX3weNzCQxq0MA8dX0HybjABRikd1+4845FjVqsWEL6hGZSS3vPFl9J/f4CO0qMk5DF3O4wQozppSaoWJtWpGsl0stVQqeTGw9f9QJ0MxQvlvNPuoFazRbvdPNjfCjnd8AEBZRJBBUEmwRhHPgBAyr0c9Bxh88yYaFXgST81/mHSjC8SAHJXQf06AQv3dxLzCPduQJa297qE0p4rE7cABGalgo69pE/ rethridge@rethridge-pc'
            - 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDcni73pY1nyb0PwgQYfPd7roCE0ROlhVlOGnDuHFouebXsNKwjtSh+tozNCYOIiN7gp2k0bHkWRSVjFN3OSZM/F8Z02+Cbb6aY3Yyd9uUlfREWriL/ktfnKzZhIa5eqNoRC2mfXHadb0mwKqaSkxrKKUUO6hHC1x5isP2E/3VZM8tNfTXQGNVNbC+5OkL1/tzgWewOMSGoVZIXDNfdp3hlCb6ac9zDnBSrPkih7IJ16JNhUh7PddNdqL3QzdBmH/7JLXD4MBOoaNVZ9MorJQ62Jb6N69B6CQsygCVT8tUtKvySiWUkNDHKThiD3spDwHgkiKlx0RY4y7L2Z4/Vvn7aJTi/808YVS8oU0ByWT8SrgPWL/tDHgA5nPciq2JG2ELyzNxPzbKgJUiwZ3LtwWVtm8JQujiXQcmqG+n8k9GC+8oJEGzjXtcELaJ5lpYvXSv64wG00YpQ01VrvJYSgupr8Bsyv9NMmgSUjm6c7zpxJQt7bG1WeJ5kiXuhp15VzV0/PuOHrAw0zVI6wxMHlJ+ed8nmm+wIGv9hJQrBGV6Md5D95aFSYwy8gRDknUbYEOECdUN+uN80qeR1uJWO2O4EbqxfxObfv303i/tIF0jyYNQkFPLekTVlMg+DpNNe7v9oJtpBYsf9OptHROZpf/P/pIXxjWAujia2LKnXudccqw== rossethridge@ross-pc'

      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
      EOF
  }

  limits = {
    cpu    = 2
    memory = "4GiB"
    // disk   = "20GiB"
  }

}

output "vm_ip_address" {
  value = lxd_instance.kube_master[0].ipv4_address
}

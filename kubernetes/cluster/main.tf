terraform {
  backend "local" { }
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

    // export TF_VAR_lxd_token='token value...'
    token = var.lxd_token
  }
}

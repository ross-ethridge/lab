terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
   remote {
    name     = "ross-pc"
    address  = "https://192.168.2.2:8443/"
    password = "password"
    default  = true
  }
}
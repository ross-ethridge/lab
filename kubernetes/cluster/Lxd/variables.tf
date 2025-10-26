variable "lxd_token" {
  description = "The token you got from the LXD server."
  type        = string
}

variable "ip_address" {
  description = "IP addresses."
  type = map(object({
    rke1 = string

  }))
  default = {
    "lab" = {
      rke1 = "192.168.1.101/24"
    }
  }
}
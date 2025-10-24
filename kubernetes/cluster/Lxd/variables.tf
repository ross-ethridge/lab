variable "lxd_token" {
  description = "The token you got from the LXD server."
  type        = string
}

variable "ip_address" {
  description = "Node IP addresses."
  type = map(object({
    rke1 = string

  }))
  default = {
    "lab" = {
      rke1 = "192.168.2.101/24"
    }
  }
}
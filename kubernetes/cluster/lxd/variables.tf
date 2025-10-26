variable "lxd_token" {
  description = "The token you got from the LXD server."
  type        = string
}

variable "ip_address" {
  description = "Node IP addresses."
  type = map(object({
    kubemaster1 = string
    kubemaster2 = string
    kubemaster3 = string
    kubeworker1 = string
    kubeworker2 = string
    kubeworker3 = string

  }))
  default = {
    "lab" = {
      kubemaster1 = "192.168.2.101/24"
      kubemaster2 = "192.168.2.102/24"
      kubemaster3 = "192.168.2.103/24"
      kubeworker1 = "192.168.2.111/24"
      kubeworker2 = "192.168.2.112/24"
      kubeworker3 = "192.168.2.113/24"
    }
  }
}
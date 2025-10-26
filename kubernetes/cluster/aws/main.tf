terraform {
  backend "local" {}
  # backend "s3" {
  #   bucket  = "ross-lab-tfstate"
  #   key     = "kube/cluster.terraform.tfstate"
  #   region  = "us-east-2"
  #   encrypt = true
  # }

  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }
}
variable "vpc" {
  type = object({
    name = string
  })
  default = {
    name = "management-ipfs-elastic-provider"
  }
}

variable "cluster_name" {
  type = string
  default = "management-ipfs-elastic-provider"
}

variable "cluster_version" {
  type = string
  default = "1.21"
}

variable "profile" {
  type = string
}

variable "region" {
  type = string
}

variable "accountId" {
  type = string
}

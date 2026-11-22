variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "namespace" {
  type    = string
  default = "jenkins"
}

variable "cluster_ca_certificate" {
  type = string
}
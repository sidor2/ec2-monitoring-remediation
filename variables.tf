variable "region" {
  default = "us-west-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = ""
}

variable "allowed_ssh_cidr" {}

variable "proj_name" {
  default = "monitoring-demo"
}
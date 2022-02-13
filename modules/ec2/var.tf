#variable for vpc_id
variable "vpc_id" {}

#var for public and private cidr
variable "public_cidr" {
  type    = list
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_cidr" {
  type    = list
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "aws_subnet_public" {}

variable "aws_subnet_private" {}

variable "target_group_arn" {}

variable "autoscaling_grp_name" {}

variable "security_groups" {}

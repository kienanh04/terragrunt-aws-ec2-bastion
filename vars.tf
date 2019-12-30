variable "project_env" { default = "Production" }
variable "project_env_short" { default = "prd" }

variable "aws_region" { default = "us-west-2" }
variable "aws_profile" { default = "default" }

variable "tags" {
  default = {}
}

variable "tfstate_bucket" { default = "example-tfstate-bucket" }
variable "tfstate_region" { default = "us-west-2" }
variable "tfstate_profile" { default = "default" }
variable "tfstate_arn" { default = "" }
variable "tfstate_key_vpc" { default = "demo/vpc/terraform.tfstate" }

variable "name" { default = "ec2" }
variable "customized_name" { default = "" }
variable "namespace" { default = "" }
variable "source_ec2_sg_tags" { default = { Type = "WebApp" } }
variable "instance_size" { default = "1" }
variable "instance_type" { default = "t3.nano" }
variable "ami" { default = "" }
variable "delete_on_termination" { default = false }
variable "volume_size" { default = "8" }
variable "ebs_optimized" { default = true }
variable "key_name" { default = "" }
variable "subnet_id" { default = "" }
variable "iam_instance_profile" { default = "" }
variable "protect_termination" { default = true }
variable "user_data" {
  description = "The user data to provide when launching the instance"
  default     = " "
}
variable "subnet_number" {
  description = "The number of the subnet: 0, 1, 2, ..."
  default     = "0"
}

variable "dns_private" { default = false }
variable "domain_local" { default = "local" }
variable "dns_private_name" { default = "" }
variable "ec2_autorecover" { default = true }

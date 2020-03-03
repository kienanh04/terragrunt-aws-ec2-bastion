provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

terraform {
  backend "s3" {}
}

data "aws_ami" "amazon2" {
  owners      = ["137112412989"]
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = "${var.tfstate_bucket}"
    key            = "${var.tfstate_key_vpc}"
    region         = "${var.tfstate_region}"
    profile        = "${var.tfstate_profile}"
    role_arn       = "${var.tfstate_arn}"
  }
}

locals {
  common_tags = {
    Env  = "${var.project_env}"
    Name = "${local.name}"
  }

  subnet_id = "${coalesce(var.subnet_id,data.terraform_remote_state.vpc.public_subnets["${var.subnet_number}"])}"
  key_name  = "${var.key_name == "" ? data.terraform_remote_state.vpc.key_name : var.key_name }"
  ami       = "${var.ami == "" ? data.aws_ami.amazon2.id : var.ami }"
  name      = "${var.customized_name == "" ? "${lower(var.project_env_short)}-${lower(var.name)}" : var.customized_name }"
  namespace = "${var.customized_name == "" ? var.namespace : "" }"

  dns_private_name_temp = "${var.namespace == "" ? "" : "${lower(var.namespace)}-"}${lower(local.name)}.${var.domain_local}"
  dns_private_name      = "${var.dns_private_name == "" ? local.dns_private_name_temp : "${var.dns_private_name}.${var.domain_local}"}"
}

data "aws_security_groups" "ec2" {
  tags = "${merge(var.source_ec2_sg_tags, map("Env", "${var.project_env}"))}"
  filter {
    name   = "vpc-id"
    values = ["${data.terraform_remote_state.vpc.vpc_id}"]
  }
}

module "ec2" {
  source  = "thanhbn87/ec2-bastion/aws"
  version = "0.1.5"

  ami           = "${local.ami}"
  name          = "${local.name}"
  namespace     = "${local.namespace}"
  instance_type = "${var.instance_type}"
  project_env   = "${var.project_env}"

  delete_on_termination = "${var.delete_on_termination}"
  volume_size           = "${var.volume_size}"
  ebs_optimized         = "${var.ebs_optimized}"

  key_name               = "${local.key_name}"
  subnet_id              = "${local.subnet_id}"
  iam_instance_profile   = "${var.iam_instance_profile}"
  vpc_security_group_ids = "${data.aws_security_groups.ec2.ids}"

  tags                = "${var.tags}"
  user_data           = "${var.user_data}"
  protect_termination = "${var.protect_termination}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  
}

## DNS local:
data "aws_route53_zone" "private" {
  count        = "${var.dns_private ? 1 : 0}"
  name         = "${var.domain_local}"
  private_zone = true
}

resource "aws_route53_record" "ec2" {
  count   = "${var.dns_private ? 1 : 0}"
  zone_id = "${element(concat(data.aws_route53_zone.private.*.id,list("")),0)}"
  name    = "${local.dns_private_name}"
  type    = "A"
  ttl     = "60"
  records = ["${module.ec2.private_ip}"]
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "key" {
  key_name   = "consul_test"
  public_key = file("consul_test.pub")
}

locals {
  env           = "my"
  consul_domain = "my.consul"
  domain_name   = "my.local"
  dns_servers   = ["10.10.10.10", "8.8.8.8"]
  subnet_ids    = ["subnet-6b21c2ds", "subnet-6b21c022", "subnet-6b21cghr"] // 3 or 1

}

module "consul_server" {
  source = "./.."

  use_dhcp_options = false

  dhcp_domain_name = local.domain_name
  dhcp_dns_servers = local.dns_servers

  env_name     = local.env
  key_name     = aws_key_pair.key.key_name
//  private_key  = file("path/to/my/secretKey")
  subnet_ids   = local.subnet_ids
  iam_policies = [aws_iam_policy.describe_tags.arn, aws_iam_policy.network_interfaces.arn]

  standalone    = false
  instance_size = "t_micro"

  use_acl           = true
  consul_env_tag    = local.env
  consul_recursors  = [cidrhost(data.aws_subnet.subnet.cidr_block, 2)]
  consul_datacenter = local.env
  consul_domain     = local.consul_domain
}


output "consul_server_private_ips" {
  value = module.consul_server.dns_resolver_ips
}

output "consul_datacenter" {
  value = local.env
}

output "consul_env_tag" {
  value = local.env
}

output "consul_domain" {
  value = local.consul_domain
}

output "consul_servers_dns" {
  value = ["consul.service.${local.env}.${local.consul_domain}"]
}

//output "consul_admin_token" {
//  value = "${module.consul_server.admin_token}"
//}

output "consul_agent_token" {
  value     = module.consul_server.agent_token
  sensitive = true
}

output "consul_encrypt_key" {
  value     = module.consul_server.encrypt_key
  sensitive = true
}

data "aws_subnet" "subnet" {
  id = local.subnet_ids[0]
}

resource "aws_iam_policy" "describe_tags" {
  name   = "IamPolicy-${local.env}--tags"
  path   = "/"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeTags"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "network_interfaces" {
  name   = "IamPolicy-${local.env}-network_interfaces"
  path   = "/"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}
data "aws_region" "current" {
}

locals {
  full_name     = "Consul"
  name          = format("%0.1s%s", lower(var.env_name), var.short_name)
  count         = var.standalone ? 1 : 3
  instance_type = {
    t_micro  = "t3.micro"
    t_small  = "t3.small"
    t_medium = "t3.medium"
    c_large  = "c5.large"
  }
  tags          = {
    Name = "${local.name}l",
    env  = var.env_name
  }
  consul_join   = ["provider=aws tag_key=consul_env tag_value=${var.consul_env_tag}"]
  consul_config = <<-EOF
  recursors           = ${jsonencode(var.consul_recursors)}
  datacenter          = "${var.consul_datacenter}"
  domain              = "${var.consul_domain}"
  encrypt             = "${random_id.encrypt_key.b64_std}"
  retry_join          = ${jsonencode(local.consul_join)}
  bootstrap_expect    = ${local.count}
  server              = true
  disable_remote_exec = true
  verify_incoming     = false
  verify_outgoing     = false
  ui                  = true
  %{ if var.use_acl }
  acl = {
    enabled        = true
    down_policy    = "extend-cache"
    default_policy = "deny"
    tokens         = {
      master       = "${data.template_file.token[0].rendered}"
      default      = "${data.template_file.token[1].rendered}"
    }
  }
  %{ endif }
  client_addr         = "0.0.0.0"
  EOF
}

data "aws_ami" "image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.base_search_ami]
  }
}

data "aws_subnet" "sn" {
  id = var.subnet_ids[0]
}

//random_id.encrypt_key.b64_std
resource "random_id" "encrypt_key" {
  byte_length = 16
  lifecycle {
    ignore_changes = all
  }
}

// 0 - master
// 1 - agent
// 2 - admin
resource "random_id" "token" {
  count       = 3
  byte_length = 16
  lifecycle {
    ignore_changes = all
  }
  keepers     = {}
}

data "template_file" "token" {
  count    = 3
  template = format(
  "%v-%v-%v-%v-%v",
  substr(random_id.token[count.index].hex, 0, 8),
  substr(random_id.token[count.index].hex, 8, 4),
  substr(random_id.token[count.index].hex, 12, 4),
  substr(random_id.token[count.index].hex, 16, 4),
  substr(random_id.token[count.index].hex, 20, 12),
  )
}

data "aws_subnet" "subnet" {
  id = var.subnet_ids[0]
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.tpl")
  vars     = {
    hostname = "${local.name}l"
    eni      = join(" ", aws_network_interface.eni_ip.*.id)
    version  = var.consul_version
    consul   = base64encode(local.consul_config)
    region   = data.aws_region.current.name
    nrinfra  = base64encode("license_key: ${var.newrelic_key}")
  }
}

data "template_file" "set_acls" {
  template = file("${path.module}/set_acls.sh")
  vars     = {
    host   = "localhost:8500"
    master = data.template_file.token[0].rendered
    agent  = data.template_file.token[1].rendered
    admin  = data.template_file.token[2].rendered
  }
}


resource "aws_network_interface" "eni_ip" {
  count             = "${local.count}"
  subnet_id         = "${element(var.subnet_ids, count.index)}"
  source_dest_check = true
  security_groups   = ["${aws_security_group.sg.id}"]
  tags {
    Name   = "${local.name}l"
    enitag = "${local.name}l"
  }
}

//////////////////////////////////////////////////////////////////
resource "aws_iam_role" "role" {
  name               = "IamRole-${var.env_name}-${var.short_name}"
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":[\"s3.amazonaws.com\",\"ec2.amazonaws.com\"]},\"Action\":\"sts:AssumeRole\"}]}"
}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = "${length(var.iam_policies)}"
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${element(var.iam_policies,count.index)}"
}

resource "aws_iam_instance_profile" "profile" {
  depends_on  = ["aws_iam_role_policy_attachment.attach"]
  name_prefix = "${aws_iam_role.role.name}"
  role        = "${aws_iam_role.role.name}"
}

/////////////////////////////////////////////////////////
resource "aws_launch_configuration" "lc" {
  name_prefix          = "${local.name}l-"
  image_id             = "${data.aws_ami.image.id}"
  instance_type        = "${lookup(local.instance_type, var.instance_size)}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.sg.id}"]
  user_data            = "${data.template_file.userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix               = "${local.name}l-"
  vpc_zone_identifier       = ["${var.subnet_ids}"]
  max_size                  = "${local.count}"
  min_size                  = "${local.count}"
  desired_capacity          = "${local.count}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  default_cooldown          = 300
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  wait_for_capacity_timeout = "5m"
  termination_policies      = ["OldestInstance", "OldestLaunchConfiguration"]
  protect_from_scale_in     = true
  lifecycle {
    prevent_destroy = false
  }
  tag {
    key                 = "Name"
    value               = "${local.name}l"
    propagate_at_launch = "True"
  }
  tag {
    key                 = "env"
    value               = "${var.env_name}"
    propagate_at_launch = "True"
  }
  tag {
    key                 = "consul_env"
    value               = "${var.consul_env_tag}"
    propagate_at_launch = "True"
  }
}

///// SET ACL BLOCK /////////
resource "null_resource" "set_acls" {
  depends_on = ["aws_autoscaling_group.asg"]
  lifecycle {
    ignore_changes = ["*"]
  }
  connection {
    host        = "${aws_network_interface.eni_ip.*.private_ip[0]}"
    user        = "ec2-user"
    private_key = "${var.private_key}"
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = ["${data.template_file.set_acls.rendered}"]
  }
}

////// SET DHCP OPTIONS ////////////////
resource "aws_vpc_dhcp_options" "opt" {
  count                = "${var.use_dhcp_options}"
  domain_name          = "${var.dhcp_domain_name}"
  domain_name_servers  = ["${aws_network_interface.eni_ip.*.private_ip}"]
  ntp_servers          = ["${var.dhcp_dns_servers}"]
  netbios_name_servers = ["${var.dhcp_dns_servers}"]
  netbios_node_type    = 2
  tags {
    Name = "vpc_dhcpoptions-${var.env_name}-consul"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_dhcp_options_association" "opta" {
  count           = "${var.use_dhcp_options}"
  vpc_id          = "${data.aws_subnet.sn.vpc_id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.opt.id}"
}

//////////////// SECURITY GROUPS ////////////////////////
resource "aws_security_group" "sg" {
  name_prefix = "${local.name}-sg-"
  description = "Security group to associate with ${local.full_name} servers in ${var.env_name} environment"
  vpc_id      = "${data.aws_subnet.sn.vpc_id}"

  tags {
    Name = "${local.name}-sg"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_ssh_10" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

// followed the doc: https://www.consul.io/docs/agent/options.html#ports-used
resource "aws_security_group_rule" "allow_consul1_10" {
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul2_10" {
  type              = "ingress"
  from_port         = 8301
  to_port           = 8302
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul3_10" {
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul4_10" {
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul5_10" {
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul6_10" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "allow_consul7_10" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${aws_security_group.sg.id}"
}

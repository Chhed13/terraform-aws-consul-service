output "master_token" {
  value = "${data.template_file.token.*.rendered[0]}"
  sensitive = true
}

output "agent_token" {
  value = "${data.template_file.token.*.rendered[1]}"
  sensitive = true
}

output "admin_token" {
  value = "${data.template_file.token.*.rendered[2]}"
  sensitive = true
}

output "encrypt_key" {
  value = "${random_id.encrypt_key.b64_std}"
  sensitive = true
}

/////////////////////////////////////////////////////////////////

output "asg_name" {
  value = "${aws_autoscaling_group.asg.name}"
}

output "asg_id" {
  value = "${aws_autoscaling_group.asg.id}"
}

output "launch_config_id" {
  value = "${aws_launch_configuration.lc.id}"
}

output "dns_resolver_ips" {
  value = "${aws_network_interface.eni_ip.*.private_ip}"
}
// Source and service //////////////////
variable "short_name" {
  type        = string
  default     = "con"
  description = "Host middle name. Better not touch it"
}

variable "use_acl" {
  default     = true
  description = "Setup ACLs or not. Default true"
}

variable "consul_version" {
  type        = string
  default     = "1.5.3"
  description = "Version of Consul service to run."
}

variable "consul_datacenter" {
  type        = string
  description = "Consul datacenter name"
}

variable "consul_domain" {
  type        = string
  default     = "consul"
  description = "Consul domain name"
}

variable "consul_env_tag" {
  type        = string
  description = "consul_env tag value on instance. Can be same as env_name"
}

variable "consul_recursors" {
  type        = list(string)
  default     = ["8.8.8.8"]
  description = "List of recursors (extentions) for DNS resolving"
}

// AWS Auto-scaling, placement and policy params /////////////////
variable "base_search_ami" {
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
  description = "AMI to search. Allow to pin fixed version. By default: upstream to latest Amazon Linux 2 iamge"
}

variable "standalone" {
  default     = true
  description = "true - up 1 node consul, false - up 3 node consul"
}

variable "instance_size" {
  type        = string
  description = "Size of cluster, can be t_micro, t_small, t_medium, c_large"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDs of subnet in different availability zones"
}

variable "iam_policies" {
  type        = list(string)
  description = "ARNs of IAM policies to attach. At least Describe Instances and Manage Network Interface must be provided"
}

variable "key_name" {
  type        = string
  description = "SSH key name in your AWS account for AWS instances"
}

variable "private_key" {
  type        = string
  default     = ""
  description = "Private key to specified by key_name. Required only to set acl procedure"
}

// Environment and infra params //////////
variable "env_name" {
  default     = ""
  description = "Envrironment tag on instance and prefix letter in name"
}

variable "use_dhcp_options" {
  default     = false
  description = "Set Consul as primary DHCP & DNS resolver. Can be switched only after initial deployment"
}

variable "dhcp_domain_name" {
  type        = string
  default     = ""
  description = "Domain name to set in DHCP options"
}

variable "dhcp_dns_servers" {
  type        = list(string)
  default     = [""]
  description = "DNS servers to set in DHCP options"
}

variable "newrelic_key" {
  type        = string
  default     = ""
  description = "License key for NewRelic infrastructure. Attach in provided"
}


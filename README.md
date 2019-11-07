# Run Consul cluster on AWS
![Consul](https://422bf3d160f51e6f9d81-50529851d44f252cc6434d6bbf378de4.ssl.cf2.rackcdn.com/Consul_VerticalLogo_FullColor-blog-list.4d55ef4f663e9f2cbca3db491b480691.png)

## Versions mapping

- 0.1: Terraform 0.11, Consul >= 1.0 
- 0.2: Terraform 0.12, Consul >= 1.0 
- 0.3: Terraform 0.12, Consul >= 1.5 

## Features

- [x] Support Consul 1.5.x version
- [x] Support TF 0.12.x version
- [x] Deploy standalone or 3 node cluster
- [x] Make initial setup of ACL on apply
- [x] Deployed in ASG and may be rotated accordingly
- [x] Can be used as primary DNS and settled in DHCP options
- [x] Upgrade via server rotation
- [x] stable IPs for DNS resolving and attachment
- [x] attach via _consul_env_ tag on instance
- [x] auto-restart in case of service failure (but never happens)
- [x] attach to NewRelic Infra if key provided
- [ ] no manage IAM policies inside module now, provide externally
- [x] based on Amazon Linux 2, no custom AMIs
- [ ] run from non-root user with 53 port DNS support


## Input variables

| Variable               |  Type  |  Default    | Description                                                 |
|------------------------|:------:|:-----------:|-------------------------------------------------------------|
| short_name             |  bool  |   "con"     | Host middle name. Better not touch it                       |
| use_acl                |  bool  |   true      | Setup ACLs or not. Default true                             |
| consul_version         | string |   1.5.3     | Version of Consul service to run.                           |
| consul_datacenter      | string |             | Consul datacenter name                                      |
| consul_domain          | string |  "consul"   | Consul domain name                                          |
| consul_env_tag         | string |             | consul_env tag value on instance. Can be same as env_name   |
| consul_recursors       |  list  | ["8.8.8.8"] | List of recursors (extentions) for DNS resolving            |
| base_search_ami        | string | "amzn2-ami-hvm-*-x86_64-gp2" | AMI to search. Allow to pin fixed version. By default: upstream to latest Amazon Linux 2 iamge |
| standalone             |  bool  |    true     | true - up 1 node consul, false - up 3 node consul           |
| instance_size          | string |             | Size of cluster, can be t_micro, t_small, t_medium, c_large |
| subnet_ids             |  list  |             | IDs of subnet in different availability zones               |
| iam_policies           |  list  |             | ARNs of IAM policies to attach. At least Describe Instances and Manage Network Interface must be provided |
| key_name               | string |             | SSH key name in your AWS account for AWS instances          |
| private_key            | string |    ""       | Private key to specified by key_name. Required only to set acl procedure |
| env_name               | string |    ""       | Envrironment tag on instance and prefix letter in name      |
| use_dhcp_options       | bool   |   false     | Set Consul as primary DHCP & DNS resolver. Can be switched only after initial deployment |
| dhcp_domain_name       | string |    ""       | Domain name to set in DHCP options                          |
| dhcp_dns_servers       | list   |   [""]      | DNS servers to set in DHCP options                          |
| newrelic_key           | string |    ""       | License key for NewRelic infrastructure. Attach in provided |

## Output variables

| Variable             |  Type  | Description              |
|----------------------|:------:|--------------------------|
| master_token         | string | Super admin token        |
| agent_token          | string | Agent token              |
| admin_token          | string | Admin token              |
| encrypt_key          | string | Encrypting key           |
| asg_name             | string | Name of ASG              |
| asg_id               | string | ASG id                   |
| launch_config_id     | string | Launch configuration id  |
| dns_resolver_ips     | list   | IPs of DNS resolvers     |
| consul_join          | list   | Consul join list(string) |


## Usage

Watch [example](./examples/consul_server.tf) for parametrization.
No creation IAM policies inside - provide at least to Describe Tags and Manage Network Interfaces.

### Use as primary DNS

__Why?__ To enable all features that Consul provide via DNS, including shortened / home (without datacenter) names

__This feature manage DHCP options of the VPC which lead in case of failure to network error. 
Follow the instruction carefully and that will be OK.__

* Initially deploy cluster with `use_dhcp_options = false`
* Insure that consul gets up and running, all nodes in cluster is green
* Change `use_dhcp_options = true` and apply one more time
* You are ready to go

If you plan to destroy Consul, want to switch back, Consul cluster is fail:
* Go to AWS console
* Open VPC - DHCP settings and switch DHCP options set to previous one, deployed with your VPC

### Setup of ACL

* Private SSH needed only for this feature. Provide it.
* Needed network connection to private network. Insure VPN is up
* Setup make by provisioner only on first apply. If you need re-setup - `taint null_resource.set_acls` first

### Upgrade

__Allways check the update on test cluster first. General Consul config may become incompatible__

* Change `consul_version` to new one and make apply. Nothing breaks here
* Connect to one [Consul server via CLI](https://www.consul.io/docs/commands/index.html#consul_http_addr) with admin token and make `consul leave`
* Then terminate that instance via AWS console or CLI
* Wait new instance to up and running via ASG policy (usually it takes 1 minute to get up, up to 5 minute to trigger policy)
* Insure in AWS console that your instance has 2 IP assigned - rear, but happen. If it was re-scheduled too fast ENI may not re-attach
  * If not: terminate on more time
* Rotate next

### If some instance failing. AWS want your instance down

* Just terminate it
  


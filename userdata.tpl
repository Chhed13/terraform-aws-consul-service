#cloud-config
manage_etc_hosts: true
preserve_hostname: false

yum_repos:
  newrelic-infra:
    name: New Relic Infrastructure
    baseurl: http://download.newrelic.com/infrastructure_agent/linux/yum/el/7/x86_64
    gpgkey: http://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg
    gpgcheck: true
    repo_gpgcheck: true
    enabled: true

packages:
  - unzip
  - telnet
  - newrelic-infra

package_upgrade: true

write_files:
  - path: /opt/install-consul.sh
    encoding: base64
    content: |
      ${install}
  - path: /etc/consul/consul.hcl
    permissions: '0644'
    encoding: base64
    content: |
      ${consul}
  - path: /etc/newrelic-infra.yml
    encoding: base64
    content: |
      ${nrinfra}

runcmd:
  - hostnamectl set-hostname ${hostname}-$(curl -s http://169.254.169.254/latest/meta-data/instance-id | tail -c 4)
  - export AWS_DEFAULT_REGION=${region}
  - while [ -z $FREE_ENI ]; do export FREE_ENI=$(aws ec2 describe-network-interfaces --network-interface-ids ${eni} --filters Name=status,Values=available,Name=availability-zone,Values=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone) --query NetworkInterfaces[0].NetworkInterfaceId | sed s/\"//g); done
  - aws ec2 attach-network-interface --network-interface-id $FREE_ENI --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --device-index 1
  - /usr/bin/bash /opt/install-consul.sh
  - systemctl start consul

output : { all : '| tee -a /var/log/cloud-init-output.log' }
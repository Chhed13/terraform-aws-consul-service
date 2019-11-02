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
  - mc
  - traceroute
  - telnet
  - docker
  - newrelic-infra

package_upgrade: true

write_files:
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
  - export FREE_ENI=$(aws ec2 describe-network-interfaces --network-interface-ids ${eni} --filters Name=status,Values=available,Name=availability-zone,Values=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone) --query NetworkInterfaces[0].NetworkInterfaceId | sed s/\"//g)
  - aws ec2 attach-network-interface --network-interface-id $FREE_ENI --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --device-index 1
  - mkdir -p /opt/consul
  - systemctl enable docker
  - systemctl restart docker
  - docker pull consul:${version}
  - docker run --net=host -d -e 'CONSUL_ALLOW_PRIVILEGED_PORTS=' --restart=unless-stopped -v /opt/consul:/consul/data -v /var/run/docker.sock:/var/run/docker.sock -v /etc/consul:/etc/consul --name consul-server consul:${version} agent -advertise=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) -dns-port=53 -config-file=/etc/consul/consul.hcl

output : { all : '| tee -a /var/log/cloud-init-output.log' }
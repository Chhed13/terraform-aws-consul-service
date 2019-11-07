#!/bin/bash
echo "Awaiting userdata to complete"

while [ ! -f /var/lib/cloud/instances/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)/boot-finished ] ;
do
      sleep 10
done
sleep 60

export CONSUL_HTTP_TOKEN=${master}

echo "Creating policies"
consul acl policy create -name anonymous -rules 'agent_prefix "" { policy = "read" } event_prefix "" { policy = "read" } key_prefix "" { policy = "read" } keyring = "read" node_prefix "" { policy = "read" } operator = "read" query_prefix "" { policy = "read" } service_prefix "" { policy = "read" }'
consul acl policy create -name agent -rules 'agent_prefix "" { policy = "write" } event_prefix "" { policy = "read" } key_prefix "" { policy = "read" } key_prefix "HotSwapServices/" { policy = "write" } keyring = "write" node_prefix "" { policy = "write" } operator = "read" query_prefix "" { policy = "read" } service_prefix "" { policy = "write" }'
consul acl policy create -name admin -rules 'agent_prefix "" { policy = "write" } event_prefix "" { policy = "write" } key_prefix "" { policy = "write" } key_prefix "HotSwapServices/" { policy = "write" } keyring = "write" node_prefix "" { policy = "write" } operator = "write" query_prefix "" { policy = "write" } service_prefix "" { policy = "write" }'

echo "Creating tokens"
consul acl token create -policy-name=agent -description="agent" -secret=${agent} -accessor=${agent}
consul acl token create -policy-name=admin -description="admin" -secret=${admin} -accessor=${admin}
consul acl token update -id=anonymous -policy-name=anonymous
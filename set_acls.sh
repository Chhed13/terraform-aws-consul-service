#!/bin/bash
master="${master}"
host="${host}"

echo "awaiting userdata to complete"

while [ ! -f /var/lib/cloud/instances/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)/boot-finished ] ;
do
      sleep 10
done
sleep 60

echo "host $host"
echo "Setting Anonymous"
curl -S \
    -X PUT \
    -H "X-Consul-Token: $master" \
    --data \
'{
  "Name": "Anonymous Token",
  "ID": "anonymous",
  "Type": "client",
  "Rules": "agent \"\" { policy = \"read\" } event \"\" { policy = \"read\" } key \"\" { policy = \"read\" } keyring = \"read\" node \"\" { policy = \"read\" } operator = \"read\" query \"\" { policy = \"read\" } service \"\" { policy = \"read\" }"
}' http://$host/v1/acl/update

err=$?
if [ 0 -ne $err ]; then
  echo "error $err: Anonymous ACL failed"
  exit $err
fi
#agent "" {
#  policy = "read"
#}
#event "" {
#  policy = "read"
#}
#key "" {
#  policy = "read"
#}
#keyring = "read"
#node "" {
#  policy = "read"
#}
#operator = "read"
#query "" {
#  policy = "read"
#}
#service "" {
#  policy = "read"
#}


echo "Setting Agent"
curl -f --output /dev/stderr \
    -X PUT \
    -H "X-Consul-Token: $master" \
    --data \
'{
  "Name": "agent",
  "ID": "${agent}",
  "Type": "client",
  "Rules": "agent \"\" { policy = \"write\" } event \"\" { policy = \"read\" } key \"\" { policy = \"read\" } key \"HotSwapServices/\" { policy = \"write\" } keyring = \"write\" node \"\" { policy = \"write\" } operator = \"read\" query \"\" { policy = \"read\" } service \"\" { policy = \"write\" }"
}' http://$host/v1/acl/create

err=$?
if [ 0 -ne $err ]; then
  echo "error $err: Agent ACL failed"
  exit $err
fi
#agent "" {
#  policy = "write"
#}
#event "" {
#  policy = "read"
#}
#key "" {
#  policy = "read"
#}
#key "HotSwapServices/" {
#  policy = "write"
#}
#keyring = "write"
#node "" {
#  policy = "write"
#}
#operator = "read"
#query "" {
#  policy = "read"
#}
#service "" {
#  policy = "write"
#}

echo "Setting Admin"
curl -f --output /dev/stderr \
    -X PUT \
    -H "X-Consul-Token: $master" \
    --data \
'{
  "Name": "admin",
  "ID": "${admin}",
  "Type": "client",
  "Rules": "agent \"\" { policy = \"write\" } event \"\" { policy = \"write\" } key \"\" { policy = \"write\" } key \"HotSwapServices/\" { policy = \"write\" } keyring = \"write\" node \"\" { policy = \"write\" } operator = \"write\" query \"\" { policy = \"write\" } service \"\" { policy = \"write\" }"
}' http://$host/v1/acl/create

err=$?
if [ 0 -ne $err ]; then
  echo "error $err: Admin ACL failed"
  exit $err
fi
#agent "" {
#  policy = "write"
#}
#event "" {
#  policy = "write"
#}
#key "" {
#  policy = "write"
#}
#keyring = "write"
#node "" {
#  policy = "write"
#}
#operator = "write"
#query "" {
#  policy = "write"
#}
#service "" {
#  policy = "write"
#}

echo "ACLs set done SUCCESS"

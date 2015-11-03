#!/bin/bash
set -e
function fail {
  echo "CRITICAL: $@"
  exit 2
}

if [ -f /root/openrc ]; then
  source /root/openrc
  neutron floatingip-list || fail 'neutron floatingip-list failed'
  neutron floatingip-create public_net || fail 'neutron floatingip-create failed'
  for net in `neutron floatingip-list | awk '/[a-z][a-z]*[0-9][0-9]*/ {print $2}'`; do
    neutron floatingip-delete $net || fail 'neutron floatingip-delete failed'
  done
else
  echo 'Critical: Openrc does not exist'
  exit 2
fi

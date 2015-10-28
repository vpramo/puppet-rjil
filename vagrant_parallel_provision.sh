#!/bin/bash
#
# Parallel provisioning for vagrant
#
  
up() {
  . newtokens.sh
  if [ ! -n $consul_discovery_token ]; then
    echo "Error fetching consul discovery token, exiting"
    exit 100
  fi
  adapter=`VBoxManage hostonlyif create | cut -d"'" -f2`
  export NIC_ADAPTER=$adapter
  echo "export NIC_ADAPTER=$adapter" > vagrant_keys
  echo "export consul_discovery_token=$consul_discovery_token" >> vagrant_keys
  vagrant up bootstrap1
  vagrant up --no-provision
  VBoxManage dhcpserver modify --ifname $adapter --disable
  #This is because of a bug in VirtualBox
  ps -ef | grep $adapter | grep VBoxNetDHCP | cut -d" " -f4 | xargs kill -9
}

provision() {
  sleep 5
  if [ ! -n $consul_discovery_token ]; then
    echo "Error fetching consul discovery token, exiting"
    exit 100
  fi
  for i in `vagrant status | grep running | awk '{print $1}'`; do 
    if [ $i != "bootstrap1" ]
      vagrant provision $i &
    fi
  done
}

destroy() {
  if [ -z $NIC_ADAPTER ]; then
    echo "Export the NIC_ADAPTER associated with the gate"
    exit 100
  fi
  vagrant destroy -f
  VBoxManage hostonlyif remove $NIC_ADAPTER
  rm -f vagrant_keys
}

case $1 in
  'destroy')
    destroy
    ;;
  'up')
    up
    provision
    ;;
  'provision')
    provision
    ;;
  'reset')
    destroy
    up
    provision
    ;;
  *)
    echo "Invalid operation. Valid operations are destroy, up, provision,reset"
    exit 100
    ;;
esac

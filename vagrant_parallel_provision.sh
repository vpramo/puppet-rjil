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
  sed -i 's/token_value/$(consul_discovery_token)/g' vagrant_keys
  source vagrant_keys
  vagrant up --no-provision
}

provision() {
  source vagrant_keys
  sleep 5
  if [ ! -n $consul_discovery_token ]; then
    echo "Error fetching consul discovery token, exiting"
    exit 100
  fi
  for i in `vagrant status | grep running | awk '{print $1}'`; do 
    vagrant provision $i &
  done
}

destroy() {
  source vagrant_keys
  vagrant destroy -f
  sed -i 's/$(consul_discovery_token)/token_value/g' vagrant_keys
}

initalize() {
  . newtokens.sh
  adapter=`VBoxManage hostonlyif create | cut -d"'" -f2`
  export NIC_ADAPTER=$adapter
  echo "export NIC_ADAPTER=$adapter" > vagrant_keys
  echo "export consul_discovery_token=token_value" >> vagrant_keys
  export layout=external
  vagrant up httpproxy1
  VBoxManage dhcpserver modify --ifname $adapter --disable
  #This is because of a bug in VirtualBox
  ps -ef | grep $adapter | grep VBoxNetDHCP | cut -d" " -f4 | xargs kill -9
}

cleanup() {
  source vagrant_keys
  vagrant destroy -f
  export layout=external
  vagrant destroy httpproxy1 -f
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
  'initalize')
    initalize
    ;;
  'cleanup')
    cleanup
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

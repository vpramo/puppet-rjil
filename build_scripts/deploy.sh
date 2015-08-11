#!/bin/bash -xe

. $(dirname $0)/common.sh

# If these aren't yet set (from credentials file, typically),
if [ -z "${consul_discovery_token}" ]
then
    consul_discovery_token=$(curl http://consuldiscovery.linux2go.dk/new)
fi

export consul_discovery_token

##
# overcast can run scripts independantly, so no need to run anything else.
# overcast is not able to resolve the environment variables in case of remote
# exec, added an issue there in overcast. Until that fixed, we have to use
# jiocloud module for the validation and all.
##

if [ "${provisioner}" == 'overcast' ]; then
    overcast deploy --cfg ${overcast_yaml:-.overcast.yaml} --cleanup ${cleanup_dir}/./cleanup-${project_tag} --suffix ${project_tag} ${mappings_arg} --key ${ssh_key_file:-${HOME}/.ssh/id_rsa.pub} ${stack:-overcloud}
else
    . $(dirname $0)/make_userdata.sh

    time python -m jiocloud.apply_resources apply ${EXTRA_APPLY_RESOURCES_OPTS} --key_name=${KEY_NAME:-combo} --project_tag=${project_tag} ${mappings_arg} environment/${layout}.yaml userdata.txt

    # This is crazy, but it seems to help A LOT
    if [ "$cloud_provider" = 'hp' ]
    then
        sleep 270
        nova list | grep test${BUILD_NUMBER} | cut -f2 -d' ' | while read uuid; do nova console-log $uuid | grep Giving.up.on.md && nova reboot $uuid || true; done
    fi
    function debug(){
        bash -c "ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate debug_timeout ${BUILD_NUMBER};python -m jiocloud.apply_resources ssh_config --project_tag=${project_tag} ${mappings_arg} environment/${layout}.yaml > ${project_tag}_ssh_config;for i in \`python -m jiocloud.apply_resources list --project_tag=${project_tag} environment/${layout}.yaml \`; do ssh -o LogLevel=Error -F ${project_tag}_ssh_config \${i} \'hostname\' ;done"
    }

    trap "debug" EXIT
fi

unset ip

while [[ ! $ip ]] ; do
  ip=$(python -m jiocloud.utils get_ip_of_node ${consul_bootstrap_node:-bootstrap1}_${project_tag})
  sleep 2;
done

time $timeout ${ping_timeout:-1200} bash -c "while ! bash -c 'ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate ping'; do sleep 5; done"
time $timeout 600 bash -c "while ! ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate trigger_update ${BUILD_NUMBER}; do sleep 5; done"

if [ "$stack" = 'undercloud' ]; then
    time $timeout 4000 bash -c "while ! echo uc1-${project_tag} | ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate verify_hosts ${BUILD_NUMBER} ; do sleep 5; done"
else
    time $timeout 4000 bash -c "while ! python -m jiocloud.apply_resources list --project_tag=${project_tag} environment/${layout}.yaml | sed -e 's/_/-/g' | ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate verify_hosts ${BUILD_NUMBER} ; do sleep 5; done"
fi
time $timeout 2400 bash -c "while ! ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate check_single_version -v ${BUILD_NUMBER} ; do sleep 5; done"
time $timeout 600 bash -c "while ! ssh -o LogLevel=Error -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate get_failures --hosts; do sleep 5; done"

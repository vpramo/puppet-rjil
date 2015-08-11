#
# Class: rjil::test::neutron
#   Adding tests for neutron services
#
# == Parameters
#
# [*fip_available*]
#   This tell whether fip is available for the cloud or not, if not available
#   do not test them.
#
# [*test_netcreate*]
#   whether to test network/subnet creation - this may not be possible for
#   undercloud.
#

class rjil::test::neutron(
  $fip_available  = true,
  $test_netcreate = true
) {

  include openstack_extras::auth_file

  include rjil::test::base

  file { '/usr/lib/jiocloud/tests/neutron-service.sh':
    content => template("rjil/tests/neutron.sh.erb"),
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $fip_available {
    file { '/usr/lib/jiocloud/tests/floating_ip.sh':
      source => 'puppet:///modules/rjil/tests/floating_ip.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }
}

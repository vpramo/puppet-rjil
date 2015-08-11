#
# This is WIP, just adding required route to get floating IP accessible now.
#
class rjil::tempest (
  $keystone_admin_token,
  $auth_host              = 'lb.keystone.service.consul',
  $auth_port              = 35357,
  $auth_protocol          = 'http',
  $service_tenant         = 'services',
  $neutron_admin_user     = 'neutron',
  $neutron_admin_password = 'neutron',
  $glance_admin_user      = 'glance',
  $glance_admin_password  = 'glance',
  $nova_admin_user        = 'nova',
  $nova_admin_password    = 'nova',
  $tempest_test_file      = '/home/jenkins/tempest_tests.txt',
  $image_name             = 'cirros',
) {

##
# Create required resources in order to run tempest
##

  file {'/etc/keystone':
    ensure => directory,
  }

  file { $tempest_test_file:
    ensure => file,
    source => "puppet:///modules/${module_name}/tempest_tests.txt",
  }

  file {'/etc/keystone/keystone.conf':
    ensure  => file,
    require => File['/etc/keystone'],
  }

  keystone_config {
    'DEFAULT/admin_token':    value => $keystone_admin_token;
    'DEFAULT/admin_endpoint': value => "${auth_protocol}://${auth_host}:${auth_port}";
  }

  File['/etc/keystone/keystone.conf'] -> Keystone_config<||>
  Keystone_config<||> -> Keystone_tenant<||>
  Keystone_config<||> -> Keystone_user<||>
  Keystone_config<||> -> Keystone_user_role<||>

  ##
  # nova config for nova_flavor
  ##
  Nova_config<||> -> Tempest_Config<||>
  nova_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_uri':          value => "${auth_protocol}://${auth_host}:${auth_port}/v2.0";
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $service_tenant;
    'keystone_authtoken/admin_user':        value => $nova_admin_user;
    'keystone_authtoken/admin_password':    value => $nova_admin_password;
  }

  ##
  # Glance image and tempest glance image id setter need keystone section in
  # /etc/glance/glance-api.conf. So adding.
  ##
  file {'/etc/glance':
    ensure => directory,
  }

  file {'/etc/glance/glance-api.conf':
    ensure  => file,
    require => File['/etc/glance'],
  }

  File['/etc/glance/glance-api.conf'] ->
  Glance_api_config<||> -> Glance_image<||>

  glance_api_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $service_tenant;
    'keystone_authtoken/admin_user':        value => $glance_admin_user;
    'keystone_authtoken/admin_password':    value => $glance_admin_password;
  }

  ##
  # Neutron_network and neutron_subnet need neutron.conf with keystone
  # configuration added. So adding appropriate entries.
  ##

  file {'/etc/neutron':
    ensure => directory,
  }

  file {'/etc/neutron/neutron.conf':
    ensure  => file,
    require => File['/etc/neutron'],
  }

  File['/etc/neutron/neutron.conf'] -> Neutron_config<||>
  Neutron_config<||> -> Neutron_network<||>
  Neutron_config<||> -> Neutron_subnet<||>

  neutron_config {
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/auth_port':         value => $auth_port;
    'keystone_authtoken/auth_protocol':     value => $auth_protocol;
    'keystone_authtoken/admin_tenant_name': value => $service_tenant;
    'keystone_authtoken/admin_user':        value => $neutron_admin_user;
    'keystone_authtoken/admin_password':    value => $neutron_admin_password;
  }

  ensure_packages([
    'python-pip',
    'git',
    'python-setuptools',
    'python-tempest',
    'python-tempest-lib',
    'python-hacking',
    'python-sphinx',
    'python-subunit',
    'python-oslosphinx',
    'python-mox',
    'python-mock',
    'python-coverage',
    'python-oslotest',
    'python-stevedore',
    'python-pbr',
    'python-anyjson',
    'python-httplib2',
    'python-jsonschema',
    'python-testtools',
    'python-boto',
    'python-paramiko',
    'python-netaddr',
    'python-ceilometerclient',
    'python-glanceclient',
    'python-keystoneclient',
    'python-novaclient',
    'python-neutronclient',
    'python-cinderclient',
    'python-heatclient',
    'python-oslo.config',
    'python-iso8601',
    'python-fixtures',
    'python-testscenarios',
    'python-ecdsa',
    'python-mox3',
    'testrepository',
    'subunit',
  ])

  class {'::tempest':
    image_name => $image_name,
  }
}


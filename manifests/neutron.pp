#
# Class: rjil::neutron
#
class rjil::neutron (
  $api_extensions_path  = undef,
  $service_provider     = undef,
  $admin_email          = 'root@localhost',
  $server_name          = 'localhost',
  $localbind_host       = '127.0.0.1',
  $public_port          = 9696,
  $localbind_port       = 19696,
  $ssl                  = false,
  $rewrites             = undef,
  $headers              = undef,
  $srv_tag                = 'real',
) {

  ##
  # Rjil tests
  ##
  include rjil::test::neutron

  ##
  # Python-six version >= 1.8.x is required for neutron server, and not handled in package. So
  # installing it prior to neutron-server.
  ##

  Package['python-six'] -> Class['::neutron::server']

  include ::neutron
  include ::neutron::server
  include ::neutron::quota

  rjil::jiocloud::logrotate { 'neutron-server':
    logfile => '/var/log/neutron/server.log'
  }

  ensure_resource('package','python-six', { ensure => 'latest' })


  ##
  # Reverse proxy
  ##

  include rjil::apache
  Service['neutron-server'] -> Service['httpd']

  ## Configure apache reverse proxy
  apache::vhost { 'neutron':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/neutron',
    error_log_file  => 'neutron.log',
    access_log_file => 'neutron.log',
    proxy_pass      => [ { path => '/', url => "http://${localbind_host}:${localbind_port}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  ##
  # neutron_config is making multiple entries for service_provider
  # I see that neutron_config just change the value of all entries there. This
  # is causig problem as there are multiple entries for service_provider in
  # default configuration (one for lb and one for VPN)
  # Because of this neutron server is not getting started. As a workaround, just
  # purging default configuration file before configuration.
  #
  # NOTE: neutron_config doesnt support multiple enties of same configuration.
  # It may have to use different method (or to extend neutron_config) to setup
  # service_provider later when it is going to have mulitple service providers.
  ##
  exec {'empty_neutron_conf':
    command     => 'mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak_puppet',
    refreshonly => true,
    subscribe   => Package['neutron-server'],
  }

  Exec['empty_neutron_conf'] -> Neutron_config<||>

  ##
  # Below configs are not there in neutron module, so adding here for now.
  # These are required for contrail configuration.
  ##

  if $api_extensions_path {
    neutron_config {'DEFAULT/api_extensions_path':
      value => $api_extensions_path,
    }
  }

  if $service_provider {
    neutron_config { 'service_providers/service_provider':
      value => $service_provider
    }
  }

  rjil::test::check { 'neutron':
    address => '127.0.0.1',
    port    => $public_port,
    ssl     => $ssl,
  }

  rjil::jiocloud::consul::service { 'neutron':
    tags          => [$srv_tag],
    port          => $public_port,
  }

  file { "/etc/neutron/policy.json":
    ensure  => file,
    owner   => 'root',
    mode    => '0644',
    source => 'puppet:///modules/rjil/neutron_policy.json',
    notify  => Service['neutron-server'],
  }
}

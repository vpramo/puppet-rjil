###
## Class: rjil::contrail
###
class rjil::contrail::analytics 
 {
  ##Include contrail collector
  class {'::contrail':
    enable_analytics => true,
    enable_config    => false,
    enable_control   => false,
    enable_webui     => false,
    enable_ifmap     => false,
    config_ip        => join(service_discover_dns('real.neutron.service.consul','name')),
  }

  # Added Tests
  rjil::test {'contrail-analytics.sh':}

  rjil::jiocloud::logrotate { 'contrail-collector-daily':
    logdir => '/var/log/contrail'
  }

  ##
  # Deleting the default config logrotates which conflict with our changes
  # The default configs have multiple logfiles in a single config which
  # conflicts with our daily files setup
  ##

  rjil::jiocloud::logrotate {'contrail-api':
    ensure => absent
  }

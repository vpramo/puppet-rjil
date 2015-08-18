###
## Class: rjil::contrail
###
class rjil::contrail::server (
  $enable_analytics = true,
  $enable_dns       = false,
  $vm_domain        = undef,
  $dns_port         = '10000'
) {

  ##
  # Added tests
  ##
  $contrail_tests = ['ifmap.sh','contrail-api.sh',
                      'contrail-control.sh','contrail-discovery.sh',
                      'contrail-schema.sh',
                      'contrail-webui-webserver.sh','contrail-webui-jobserver.sh']
  rjil::test {$contrail_tests:}

  if $enable_analytics {
    rjil::test {'contrail-analytics.sh':}
  }

  include ::contrail
  if $enable_dns and $vm_domain {
    include dnsmasq
    dnsmasq::conf { 'contrail':
      ensure  => present,
      content => "server=/${vm_domain}/127.0.0.1#${dns_port}",
    }
    rjil::test {'contrail-dns.sh':}
  }


  $contrail_logs = ['contrail-api-daily',
                    'contrail-discovery-daily',
                    'contrail-schema-daily',
                    'contrail-svc-monitor-daily',
                    'contrail-api-0-zk-daily',
                    'contrail-collector-daily'
  ]

  rjil::jiocloud::logrotate { $contrail_logs:
    logdir => '/var/log/contrail'
  }
  
  ##
  # The logs which support higher filesize need either a sighup or
  # a copytruncate to rotate properly (else the process will keep writing to
  # older logfile. Using copytruncate to minimize any potential issue w/ sighup
  ##

  $contrail_logs_copytruncate = ['contrail-control',
                                'contrail-dns',
                                'contrail-ifmap-server',
  ]
  
  rjil::jiocloud::logrotate { $contrail_logs_copytruncate:
    logdir       => '/var/log/contrail',
    copytruncate => true,
  }
  
  include rjil::contrail::logrotate::consolidate

  ##
  # Deleting the default config logrotates which conflict with our changes
  # The default configs have multiple logfiles in a single config which
  # conflicts with our daily files setup
  ##
  $contrail_logrotate_delete = ['contrail-config',
                                'contrail-config-openstack',
                                'contrail-analytics',
                                'ifmap-server',
                                ]
  rjil::jiocloud::logrotate { $contrail_logrotate_delete:
    ensure => absent
  }
  
}

#
# Class: rjil::jiocloud
# This is called by rjil::base for setting up of repositories, consul role, puppet and system upgrade related stuff
#

class rjil::jiocloud (
  $consul_role = 'agent'
) {

  if ! member(['agent', 'server', 'bootstrapserver'], $consul_role) {
    fail("consul role should be agent|server|bootstrapserver, not ${consul_role}")
  }

  include rjil::system::apt

  # ensure that python-jiocloud is installed before
  # consul and dnsmasq. This is b/c these packages
  # can introduce race conditions that effect dns
  # and we cannot currently recover if we fail to
  # install python-jiocloud
  ensure_resource('package','python-six', { ensure => 'latest' })
  package { 'python-jiocloud':
    before => [Package['dnsmasq'], Package['consul']]
  }

  if $consul_role == 'bootstrapserver' {
    include rjil::jiocloud::consul::cron
  } else {
    $addr = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
    dns_blocker {  $addr:
      try_sleep     => 10,
      tries         => 100,
      before        => Service['consul'],
    }
  }
  include "rjil::jiocloud::consul::${consul_role}"

  include rjil::jiocloud::consul::base_checks

  package { 'run-one':
    ensure => present,
  }

  file { '/usr/local/bin/jiocloud-update.sh':
    source => 'puppet:///modules/rjil/update.sh',
    mode => '0755',
    owner => 'root',
    group => 'root'
  }

  file { '/usr/local/bin/maybe-upgrade.sh':
    source => 'puppet:///modules/rjil/maybe-upgrade.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root'
  }
  cron { 'maybe-upgrade':
    command => 'run-one /usr/local/bin/maybe-upgrade.sh 2>&1 | logger',
    user    => 'root',
    require => Package['run-one'],
  }

  ini_setting { 'templatedir':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'templatedir',
  }

  ini_setting { 'modulepath':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'modulepath',
  }

  ini_setting { 'manifestdir':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'manifestdir',
  }

 #Adding override configuration for dnsmasq on all compute nodes to
 #ensure dnsmasq does not pick Cnames from /etc/hosts. This will enable
 #any prod VM's to resolve api.jiocloudservices.com to public IP
 include rjil::jiocloud::dnsrewrite

}

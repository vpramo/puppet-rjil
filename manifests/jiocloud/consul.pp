# Class: rjil::jiocloud::consul
#
class rjil::jiocloud::consul(
  $config_hash,
  $encrypt = false,
) {
  include dnsmasq

  dnsmasq::conf { 'consul':
    ensure  => present,
    content => 'server=/consul/127.0.0.1#8600',
  }

  if $encrypt {
    $encrypt_hash = {'encrypt' => $encrypt}
  } else {
    $encrypt_hash = {}
  }

  $overridden_hash = merge($encrypt_hash, $config_hash)

  class { '::consul':
    install_method    => 'package',
    ui_package_name   => 'consul-web-ui',
    ui_package_ensure => 'absent',
    bin_dir           => '/usr/bin',
    config_hash       => $overridden_hash,
    purge_config_dir  => true,
  }
  exec { "reload-consul":
    command     => "/usr/bin/consul reload",
    refreshonly => true,
    subscribe   => Service['consul'],
  }
  File['/etc/consul'] ~> Exec['reload-consul']

##
# Adding log folder for using with checks as required
# Cannot use the respective service directory as consul user cannot
# write to them
##

  file { '/var/log/consul':
    ensure => directory,
    owner  => 'consul',
    require => [ User['consul'] ],
  }

}

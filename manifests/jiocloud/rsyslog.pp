# Class: rjil::jiocloud::rsyslog
# Class for configuring rsyslog

class rjil::jiocloud::rsyslog(
  $port         = '514',
  $enable_udp   = 'true',
  $enable_tcp   = 'true',
  $tmpl_filter  = {},
  $cmservice_ip = undef,
  $ilo_subnet   = undef,
  $ilo_netmask  = undef,
  $cmservice_gw = undef,
 )
{
  include ::network2
  if $ip_addr{
    if $::ipaddress_em3{
      $conf_interface = 'em4'
    }
    elsif $::ipaddress_em4{
      $conf_interface = 'em3'
    }
    network2::interface{$conf_interface:
      ipaddress   => $cmservice_ip,
      netmask     => '255.255.255.0',
    }
    network2::route{$conf_interface:
      ipaddress   => [$ilo_subnet],
      gateway     => [$cmservice_gw],
      netmask     => [$ilo_netmask],
    }
  }
  file{'/var/log/compute':
    ensure  => 'directory',
  }

  file{'/var/log/network':
    ensure  => 'directory',
    require => File['/var/log/compute']
  }

  include rsyslog
  class{'rsyslog::server':
    enable_tcp                => $enable_tcp,
    enable_udp                => $enable_udp,
    enable_relp               => false,
    server_dir                => '/var/log/',
    content                   => template('rjil/rjil-rsyslog.erb'),
    custom_config             => undef,
    port                      => $port,
    address                   => '*',
    high_precision_timestamps => false,
    log_templates             => false,
    require                   => File['/var/log/network']
  }
}

# Class: rjil::jiocloud::rsyslog
# Class for configuring rsyslog

class rjil::jiocloud::rsyslog(
  $port         = '514',
  $enable_udp   = 'true',
  $enable_tcp   = 'true',
  $tmpl_filter  = {},
)
{
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

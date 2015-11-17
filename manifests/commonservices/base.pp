# # Commonservices base

class rjil::commonservices::base ($dummyarg = 'dummyarg') {
  file { '/var/www':
    ensure => 'link',
    target => '/mnt/data/var/www'
  }

  apache::custom_config { 'conf_enabled_include': content => 'IncludeOptional /etc/apache2/conf-enabled/*conf' }

  class { 'apache::mod::proxy': }

  class { 'apache::mod::proxy_http': }

}

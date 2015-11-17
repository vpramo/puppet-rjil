define rjil::commonservices::jenkins::cloudenv (
  $env_vars = {
  }
  ,
  $mappings = {
  }
) {
  file { "/var/lib/jenkins/cloud.${name}.env":
    content => template('rjil/cloudenv.erb'),
    owner   => jenkins,
    group   => jenkins,
    mode    => '0600'
  }

  file { "/var/lib/jenkins/cloud.${name}.map.yaml":
    content => template('rjil/cloudmap.erb'),
    owner   => jenkins,
    group   => jenkins,
    mode    => '0600'
  }
}

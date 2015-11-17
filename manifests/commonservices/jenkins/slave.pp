#
# jenkins build slave
#
class rjil::commonservices::jenkins::slave (
  $key = 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCvzdgrPlMiFFE4F+tK0INhGhZGqHQCHYMlMcXjUMSJCu7DMetDyIcoZZyMXWtvjszmbnM8hEtJPrMeBcCigTpw6yZmZT1grhyv6XoSX9ig+NM+vvipsUkGA2oKLEe0jQve0PiJWPj2DGn9xroZzxqAz7zVdLJcqU/sspLlFn4sVqqD32fIIltI4jnIfmRlj9LK+tUW3ifjeuG40rFVLhF81szGybPRLQ8ZLtiuti1/4DBtjkLDkS2qkdrTBJfCNY0bWkyvKVRqdEm3YEJ2+y1HXpKp4vmqkagFa1s45H1Pij/7hiupX62FZQPWB2YDpISLfWWgyzIHo5BTzJXs5Wfd',
) {
  include ::rjil::commonservices::jenkins

  group { 'jiojenkins': ensure => 'present', }

  user { 'jiojenkins':
    ensure     => 'present',
    gid        => 'jiojenkins',
    managehome => true,
    groups     => ['sbuild'],
    require    => Package['sbuild']
  }

  file { '/home/jiojenkins/.gitconfig':
    owner  => 'jiojenkins',
    group  => 'jiojenkins',
    source => 'puppet:///modules/rjil/jenkins-gitconfig',
    mode   => '0644'
  }

  ssh_authorized_key { 'jiojenkins':
    user => 'jiojenkins',
    type => 'ssh-rsa',
    key  => $key,
  }

  exec { 'fetch-repo':
    command => 'wget -O /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo',
    creates => '/usr/local/bin/repo'
  } ->
  file { '/usr/local/bin/repo': mode => '0755' }

  exec { 'sbuild-keygen':
    command => 'sbuild-update --keygen',
    require => [Package['sbuild'], Package['haveged']],
    creates => '/var/lib/sbuild/apt-keys/sbuild-key.pub'
  }

  rjil::commonservices::jenkins::slave::schroot { 'trusty': }

  rjil::commonservices::jenkins::slave::schroot { 'precise': }
}

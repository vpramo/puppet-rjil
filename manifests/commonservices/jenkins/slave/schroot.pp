define rjil::commonservices::jenkins::slave::schroot ($user = 'ubuntu') {
  $release = $name

  exec { "mk-sbuild-${release}":
    command => "su -c 'mk-sbuild ${release}' ${user}",
    unless  => "schroot -l | grep chroot:${release}-${::architecture}",
    require => Package['sbuild'],
    timeout => 20 * 60,
  }

  exec { "add-rustedhalo-repo-${release}":
    command     => "schroot -c source:${release}-${::architecture} -u root -- bash -c 'wget -O jiocloud.deb ; http://jiocloud.rustedhalo.com/ubuntu/jiocloud-apt-${release}.deb; dpkg -i jiocloud.deb'",
    refreshonly => true,
    subscribe   => Exec["mk-sbuild-${release}"]
  }

  exec { "add-proxy-${release}":
    command     => "schroot -c source:${release}-${::architecture} -u root -- bash -c 'echo Acquire::Http::Proxy \\\"http://127.0.0.1:3142/\\\"\\; > /etc/apt/apt.conf.d/90proxy'",
    refreshonly => true,
    subscribe   => Exec["mk-sbuild-${release}"]
  }
}

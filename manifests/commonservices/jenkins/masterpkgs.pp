class rjil::commonservices::jenkins::masterpkgs {
  include reprepro

  dnsmasq::conf { 'staging':
    ensure  => present,
    content => 'server=10.140.218.59',
  }

  $gate_pkgs = ['libxml2-dev', 'libxslt1-dev']

  package { $gate_pkgs: }

}

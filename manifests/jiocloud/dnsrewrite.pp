class rjil::jiocloud::dnsrewrite($content='#no-hosts'){
  include dnsmasq

  dnsmasq::conf { 'host_override':
    ensure  => present,
    content => $content,
  }


}

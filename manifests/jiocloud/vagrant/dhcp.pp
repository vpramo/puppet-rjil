##
# httpproxy in vagrant is used for providing DHCP to rest of nodes as well
# We cannot use vagrant DHCP as the lease time is very less
# Any change in network causes a new IP and hence failure in puppet-rjil setup

class rjil::jiocloud::vagrant::dhcp {
  if ($::virtual == 'virtualbox') {
    include dnsmasq

    dnsmasq::conf { 'vagrant_dhcp':
      ensure => present,
      source => 'puppet:///modules/rjil/vagrant_bootstrap_dhcp',
    }
  }
}

#
# Class rjil::jiocloud::dhcp
#  To setup isc-dhcp server to serve as dhcp server for ilo
#

class rjil::jiocloud::dhcp (
  $dnsdomain           = [ 'ilo.jio'],
  $nameservers         = ['8.8.8.4','8.8.8.8'],
  $interface           = 'eth0',
  $ntpservers          = [$::ipaddress],
  $fakenetwork         = '100.100.100.0',
  $fakenetmask         = '255.255.255.0',
  $dhcppools           = {},
  $server_ipaddress    = undef,
  $server_netmask      = undef,
  $server_network      = undef,
  $configure_interface = true,
  $apparmor_rules      = {},
) {

  ##
  # Setup the network interface with static IP, and then configure dhcp server
  ##
  if $configure_interface {
    rjil::netconfig::interface { $interface:
      method    => 'static',
      ipaddress => $server_ipaddress,
      netmask   => $server_netmask,
      network   => $server_network,
    }
  }

  ##
  # setup apparmor rules
  ##
  create_resources('rjil::apparmor::rule',$apparmor_rules)

  #Rjil::Netconfig::Interface[$interface] -> Class['dhcp']

  ##
  # Setup dhcp server
  ##
  class {'::dhcp':
    dnsdomain   => $dnsdomain,
    nameservers => $nameservers,
    ntpservers  => $ntpservers,
    interfaces  => [$interface],
  }

  ##
  # No service will be given on this subnet (thus fakesubnet), but declaring it helps the
  # DHCP server to understand the network topology, so that it can provide
  # IPs from appropriate subnet according to the dhcp client VLAN.
  ##
  ::dhcp::pool{'fakenet':
    network => $fakenetwork,
    mask    => $fakenetmask,
  }


  ##
  # WARNING: if rjil::jiocloud::dhcp::dhcppools: hiera DO NOT contain the subnet of the
  # $rjil::jiocloud::dhcp::interfaces, the dhcp server will fail to start.
  #
  # TODO: To go through rjil::jiocloud::dhcp::dhcppools hash and fail if the
  # subnets of $rjil::jiocloud::dhcp::interfaces are not there in the list.
  ##

  create_resources('rjil::jiocloud::dhcp::pool', $dhcppools)
}

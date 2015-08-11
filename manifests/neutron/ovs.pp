#
# Class: rjil::neutron::ovs
#

class rjil::neutron::ovs(
  $gateway,
  $br_address            = undef,
  $br_netmask            = undef,
  $br_network            = undef,
  $br_name               = 'br-ctlplane',
  $br_physical_interface = 'eth0',
  $nameservers           = undef,
  $domain                = ['openstack.local'],
  $l3_agent_enabled      = false,
  $swap_macs             = false,
) {

  $br_name_for_facter = regsubst($br_name,'-','_','G')

  if ! $br_address {
    $ipaddr_phy_iface = inline_template("<%= scope.lookupvar('ipaddress_' + @br_physical_interface) %>")
    $ipaddr_br_iface  = inline_template("<%= scope.lookupvar('ipaddress_' + @br_name_for_facter) %>")

    if $ipaddr_br_iface {
      $br_address_orig = $ipaddr_br_iface
    } elsif $ipaddr_phy_iface {
      $br_address_orig = $ipaddr_phy_iface
    }
  } else {
    $br_address_orig = $br_address
  }

  if ! $br_netmask {
    $netmask_phy_iface = inline_template("<%= scope.lookupvar('netmask_' + @br_physical_interface) %>")
    $netmask_br_iface  = inline_template("<%= scope.lookupvar('netmask_' + @br_name_for_facter) %>")

    if $netmask_br_iface {
      $br_netmask_orig = $netmask_br_iface
    } elsif $netmask_phy_iface {
      $br_netmask_orig = $netmask_phy_iface
    }
  } else {
    $br_netmask_orig = $br_netmask
  }


  if ! $br_network {
    $network_phy_iface = inline_template("<%= scope.lookupvar('network_' + @br_physical_interface) %>")
    $network_br_iface  = inline_template("<%= scope.lookupvar('network_' + @br_name_for_facter) %>")

    if $network_br_iface {
      $br_network_orig = $network_br_iface
    } elsif $network_phy_iface {
      $br_network_orig = $network_phy_iface
    }
  } else {
    $br_network_orig = $br_network
  }

  contain ::rjil::neutron

  contain ::neutron::plugins::ml2

  contain ::neutron::agents::ml2::ovs

  contain ::neutron::agents::dhcp

  ##
  # lock_path is required to get dhcp worked, $state_path is not supposed to be
  # resolved in puppet, so single quoted.
  ##
  neutron_config {'DEFAULT/lock_path': value => '$state_path/lock'}

  ##
  # Undercloud will not need l3 agent.
  ##
  if $l3_agent_enabled {
    contain ::neutron::agents::l3
  }

  ##
  # gate/virtual environments may need to swap the mac address between
  # physical and the bridge interface, as neutron will not allow to send packets
  # to different mac address.
  #
  # If swap_macs, network should not be reconfigured before the macaddress fact
  # for bridge interface (or any other fact for that interface), otherwise macs
  # would not be swapped because of the fact that the facts and functions are getting
  # created on compile phase where the bridge would be created on execution phase.
  ##
  if $swap_macs {
    if has_interface_with($br_name_for_facter) {
      if inline_template("<%= scope.lookupvar('ipaddress_' + @br_physical_interface) %>") {
        $br_mac = inline_template("<%= scope.lookupvar('macaddress_' + @br_physical_interface) %>")
        $physical_mac = inline_template("<%= scope.lookupvar('macaddress_' + @br_name_for_facter) %>")
      } elsif inline_template("<%= scope.lookupvar('ipaddress_' + @br_name_for_facter) %>") {
        $br_mac = inline_template("<%= scope.lookupvar('macaddress_' + @br_name_for_facter) %>")
        $physical_mac = inline_template("<%= scope.lookupvar('macaddress_' + @br_physical_interface) %>")
      }

      rjil::netconfig::interface { $br_physical_interface:
        method     => 'manual',
        options    => {
            'up' => 'ifconfig $IFACE 0.0.0.0 up'
          },
        onboot     => true,
        macaddress => $physical_mac,
      }

      rjil::netconfig::interface { $br_name:
        method        => 'static',
        macaddress    => $br_mac,
        ipaddress     => $br_address_orig,
        netmask       => $br_netmask_orig,
        network       => $br_network_orig,
        gateway       => $gateway,
        nameservers   => $nameservers,
        searchdomains => $domain,
        options       => {
            'up'   => "iptables -t nat -A PREROUTING -d 169.254.169.254/32 -i \$IFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination ${br_address_orig}:8775",
            'down' => "iptables -t nat -D PREROUTING -d 169.254.169.254/32 -i \$IFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination ${br_address_orig}:8775"
          },
        require       => [ Vs_bridge[$br_name],
                          Vs_port[$br_physical_interface] ]
      }
    }
  } else {
    rjil::netconfig::interface { $br_physical_interface:
        method     => 'manual',
        options    => {
            'up' => 'ifconfig $IFACE 0.0.0.0 up'
          },
        onboot     => true,
      }

    rjil::netconfig::interface { $br_name:
      method        => 'static',
      ipaddress     => $br_address_orig,
      netmask       => $br_netmask_orig,
      network       => $br_network_orig,
      gateway       => $gateway,
      nameservers   => $nameservers,
      searchdomains => $domain,
      options       => {
          'up'   => "iptables -t nat -A PREROUTING -d 169.254.169.254/32 -i \$IFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination ${br_address_orig}:8775",
          'down' => "iptables -t nat -D PREROUTING -d 169.254.169.254/32 -i \$IFACE -p tcp -m tcp --dport 80 -j DNAT --to-destination ${br_address_orig}:8775"
        },
      require       => [ Vs_bridge[$br_name],
                        Vs_port[$br_physical_interface] ]
    }
  }

}

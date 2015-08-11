##
# Class: rjil::neutron::network::undercloud
# == Purpose: To create undercloud network
##
class rjil::neutron::network::undercloud (
  $gateway,
  $br_name                   = 'br-ctlplane',
  $network_name              = 'ctlplane',
  $subnet_name               = 'ctlplane',
  $tenant_name               = 'services',
  $provider_network_type     = 'flat',
  $provider_physical_network = 'ctlplane',
  $cidr                      = undef,
  $pool_start                = undef,
  $pool_end                  = undef,
  $host_routes               = undef,
  $router_external           = true,
  $dns_nameservers           = [],
) {

  $br_name_for_fact = regsubst($br_name,'-','_','G')

  if ! $cidr {
    $br_netmask  = inline_template("<%= scope.lookupvar('netmask_' + @br_name_for_fact) %>")
    $cidr_orig = netmask2cidr($br_netmask)
  } else {
    $cidr_orig = $cidr
  }

  if ! $host_routes {
    $ipaddr_bridge = inline_template("<%= scope.lookupvar('ipaddr_' + @br_name_for_fact) %>")
    if $ipaddr_bridge {
      $host_routes_orig = ["destination=169.254.169.254/32,nexthop=${ipaddr_bridge}"]
    }
  } else {
    $host_routes_orig = $host_routes
  }

  rjil::neutron::network{'ctlplane':
    network_name              => $network_name,
    subnet_name               => $subnet_name,
    cidr                      => $cidr_orig,
    tenant_name               => $tenant_name,
    provider_network_type     => $provider_network_type,
    provider_physical_network => $provider_physical_network,
    router_external           => $router_external,
    host_routes               => $host_routes_orig,
    pool_start                => $pool_start,
    pool_end                  => $pool_end,
    gateway_address           => $gateway,
    dns_nameservers           => $dns_nameservers,
  }

}

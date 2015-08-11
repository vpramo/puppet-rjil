##
# Create network and subnet
##

define rjil::neutron::network (
  $network_name              = "${name}_default_net",
  $subnet_name               = "${name}_default_subnet",
  $cidr                      = '192.168.0.0/24',
  $tenant_name               = $name,
  $provider_network_type     = undef,
  $provider_physical_network = "${name}_default_net",
  $router_external           = false,
  $pool_start                = undef,
  $pool_end                  = undef,
  $gateway_address           = undef,
  $host_routes               = [],
  $enable_dhcp               = true,
  $ip_version                = '4',
  $shared                    = false,
  $dns_nameservers           = [],
) {

  neutron_network { $network_name:
    ensure                    => present,
    shared                    => $shared,
    tenant_name               => $tenant_name,
    router_external           => $router_external,
    provider_network_type     => $provider_network_type,
    provider_physical_network => $provider_physical_network,
  }

  if $pool_start {
    $allocation_pools = ["start=${pool_start},end=${pool_end}"]
  }

  neutron_subnet { $subnet_name:
    ensure           => present,
    cidr             => $cidr,
    ip_version       => $ip_version,
    allocation_pools => $allocation_pools,
    gateway_ip       => $gatewau_address,
    enable_dhcp      => $enable_dhcp,
    host_routes      => $host_routes,
    dns_nameservers  => $dns_nameservers,
    network_name     => $network_name,
    tenant_name      => $tenant_name,
  }
}

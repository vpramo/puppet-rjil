##
# Define: rjil::keystone::tenant
#
# == Purpose: create the users, tenants
#
##
define rjil::keystone::tenant (
  $tenant_name    = $name,
  $enabled        = true,
  $create_network = true,
) {

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => $enabled,
  }

  ##
  # It may be useful to have a default network with subnet created. Another
  # reason to create the networks because we may hit contrail bug 1353325 if we
  # anted to use rjil::neutron::contrail::fip_pool
  ##
  if $create_network {
    rjil::keystone::default_network {$tenant_name: }
  }
}

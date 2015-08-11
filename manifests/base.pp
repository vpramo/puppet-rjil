#
# Class rjil::base
#
class rjil::base (
  $self_signed_cert = false,
) {
  include rjil::jiocloud
  include rjil::system
  include logrotate::base
  include rjil::jiocloud::dns
  include rjil::default_manifest
  include rjil::system::sensitive_services
  ##
  # In case of self signed certificate mostly all of the servers need to trust
  # tht certificate as it is required to do api calls to any openstack services
  # in case of ssl enabled.
  ##
  if $self_signed_cert {
    include rjil::trust_selfsigned_cert
  }

  ##
  # New kind of ipaddress and interface facts (ipaddress and interface based on
  # subnet assigned to them) are raising new problem - in case
  # of a misconfiguration of subnets, those facts can return null values for
  # those facts. In that case, puppet run should explicitely fail to avoid the
  # system to go into invalid state.
  # NOTE: This code assume the fact is only used for private_address,
  # public_address, private_interface, public_interface. If in future those
  # facts used for anything else, they must be validated either here or in
  # appropriate code.
  ##

  if ! hiera('private_address') {
    fail("hiera data for 'private_address' is not known")
  } elsif ! hiera('private_interface') {
    fail("Hiera data for 'private_interface' is not known")
  } elsif ! hiera('public_address') {
    fail("hiera data for 'public_address' is not known")
  } elsif ! hiera('public_interface') {
    fail("Hiera data for 'public_interface' is not known")
  }

}


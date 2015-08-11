#
# Define: rjil::jiocloud::dhcp::pool
#  To
#
define rjil::jiocloud::dhcp::pool (
  $network,
  $mask,
  $range            = undef,
  $gateway          = undef,
  $oncommit         = undef,
  $onrelease        = undef,
  $onexpiry         = undef,
  $files            = {},
) {

  ::dhcp::pool{ $name:
    network   => $network,
    mask      => $mask,
    range     => $range,
    gateway   => $gateway,
    oncommit  => $oncommit,
    onrelease => $onrelease,
    onexpiry  => $onexpiry,
  }

  create_resources('file',$files,{ensure => present, mode => '0644', owner => 'dhcpd', group => 'dhcpd'})

}

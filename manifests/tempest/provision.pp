#
# This is WIP, just adding required route to get floating IP accessible now.
#
class rjil::tempest::provision (
  $auth_host              = 'identity.jiocloud.com',
  $auth_port              = 5000,
  $auth_protocol          = 'https',
  $service_tenant         = 'services',
  $neutron_admin_user     = 'neutron',
  $neutron_admin_password = 'neutron',
  $configure_neutron      = true,
  $image_source           = 'http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img',
  $convert_to_raw         = true,
  $image_name             = 'cirros',
  $staging_path           = '/opt/staging',
  $is_public              = 'yes',
  $container_format       = 'bare',
  $disk_format            = 'qcow2',
) {

##
# Create required resources in order to run tempest
##

  if $configure_neutron {
    ##
    # Neutron_network and neutron_subnet need neutron.conf with keystone
    # configuration added. So adding appropriate entries.
    ##

    file {'/etc/neutron':
      ensure => directory,
    }

    file {'/etc/neutron/neutron.conf':
      ensure  => file,
      require => File['/etc/neutron'],
    }

    File['/etc/neutron/neutron.conf'] -> Neutron_config<||>
    Neutron_config<||> -> Neutron_network<||>
    Neutron_config<||> -> Neutron_subnet<||>

    neutron_config {
      'keystone_authtoken/auth_host':         value => $auth_host;
      'keystone_authtoken/auth_port':         value => $auth_port;
      'keystone_authtoken/auth_protocol':     value => $auth_protocol;
      'keystone_authtoken/admin_tenant_name': value => $service_tenant;
      'keystone_authtoken/admin_user':        value => $neutron_admin_user;
      'keystone_authtoken/admin_password':    value => $neutron_admin_password;
    }
  }

  include ::staging

  staging::file {"image_stage_${image_name}":
    source => $image_source,
    target => "${staging_path}/${image_name}"
  }

  if $convert_to_raw {

    package {'qemu-utils':
      ensure => installed,
    }

    exec {'convert_image_to_raw':
      command => "qemu-img convert -O raw ${staging_path}/${image_name} ${staging_path}/${image_name}.img",
      creates => "${staging_path}/${image_name}.img",
      require => [ Staging::File["image_stage_${image_name}"], Package['qemu-utils']],
    }

    $image_source_path = "${staging_path}/${image_name}.img"
    $disk_format_l = 'raw'
  } else {
    $image_source_path = "${staging_path}/${image_name}"
    $disk_format_l = $disk_format
  }
  class {'::tempest::provision':
    image_source => $image_source_path,
    disk_format  => $disk_format_l,
    imagename    => $image_name
  }
}


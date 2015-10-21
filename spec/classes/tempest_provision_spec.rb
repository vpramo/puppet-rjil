require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::tempest::provision' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
    }
  end

  let :hiera_data do
    {
      'tempest::tempest_repo_uri'    => 'https://github.com/openstack/tempest.git',
      'tempest::image_name'          => 'cirros',
      'tempest::image_name_alt'      => 'cirros',
      'tempest::flavor_ref'          => 1,
      'tempest::admin_password'      => 'tempest_admin',
      'tempest::admin_username'      => 'tempest_admin',
      'tempest::tenant_name'         => 'tempest',
      'tempest::username'            => 'tempest',
      'tempest::password'            => 'tempest',
      'tempest::identity_uri'        => 'http://identity.url',
      'tempest::neutron_available'   => true,
      'tempest::public_network_name' => 'net',
      'tempest::fixed_network_name'  => 'net_tempest',
      'tempest::setup_venv'          => true,
      'rjil::tempest::keystone_admin_token' => 'token',
    }
  end

  context 'with defaults' do

    it do
      should contain_file('/etc/neutron').with_ensure('directory')

      should contain_file('/etc/neutron/neutron.conf').with(
        {
          :ensure  => 'file',
          :require => 'File[/etc/neutron]',
        }
      )

      {
        'keystone_authtoken/auth_host'         => 'identity.jiocloud.com',
        'keystone_authtoken/auth_port'         => 5000,
        'keystone_authtoken/auth_protocol'     => 'https',
        'keystone_authtoken/admin_tenant_name' => 'services',
        'keystone_authtoken/admin_user'        => 'neutron',
        'keystone_authtoken/admin_password'    => 'neutron',
      }.each do |k,v|
        should contain_neutron_config(k).with_value(v)
      end

      should contain_class('staging')

      should contain_staging__file('image_stage_cirros').with(
        {
          :source => 'http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img',
          :target => '/opt/staging/cirros'
        }
      )

      should contain_package('qemu-utils')

      should contain_exec('convert_image_to_raw').with(
        {
          :command => 'qemu-img convert -O raw /opt/staging/cirros /opt/staging/cirros.img',
          :creates => '/opt/staging/cirros.img',
          :require => '[Staging::File[image_stage_cirros]{:name=>"image_stage_cirros"}, Package[qemu-utils]{:name=>"qemu-utils"}]',
        }
      )

      should contain_class('tempest::provision').with_image_source('/opt/staging/cirros.img')

    end
  end

  context 'without convert_to_raw' do
    let :params do
      {
        :convert_to_raw => false,
      }
    end

    it 'should not convert' do

      should_not contain_exec('convert_image_to_raw')

      should contain_class('tempest::provision').with_image_source('/opt/staging/cirros')
    end
  end

end

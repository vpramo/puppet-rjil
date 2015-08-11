require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::test::neutron' do

  let :hiera_data do
    {
      'openstack_extras::auth_file::admin_password' => 'pass'
    }
  end

  let :facts do
    {
      'hostname' => 'node1'
    }
  end

  context 'with defaults' do
    it do 
      should contain_class('rjil::test::base')
      should contain_class('openstack_extras::auth_file')
    end

    it do
      should contain_file('/usr/lib/jiocloud/tests/neutron-service.sh') \
        .with_content(/neutron net-create/) \
        .with_owner('root') \
        .with_group('root') \
        .with_mode('0755')
    end

    it do
      should contain_file('/usr/lib/jiocloud/tests/floating_ip.sh') \
        .with_source('puppet:///modules/rjil/tests/floating_ip.sh') \
        .with_owner('root') \
        .with_group('root') \
        .with_mode('0755')
    end
  end

  context 'without fip_available, test_netcreate' do
    let :params do
      {
        :test_netcreate => false,
        :fip_available  => false,
      }
    end

    it do
      should_not contain_file('/usr/lib/jiocloud/tests/neutron-service.sh') \
        .with_content(/neutron net-create/)

      should_not contain_file('/usr/lib/jiocloud/tests/floating_ip.sh')
    end
  end

end

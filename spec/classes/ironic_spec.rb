require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::ironic' do

  let :hiera_data do
    {
      'nova::compute::ironic::keystone_password' => 'pass',
      'ironic::rabbit_password'                  => 'rabbit',
      'ironic::api::admin_password'              => 'admin',
      'ironic::keystone::auth::password'          => 'pass',
    }
  end

  let :facts do
    {
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '14.04',
      :osfamily               => 'Debian',
      :lsbdistid              => 'ubuntu',
      :concat_basedir         => '/tmp',
      :ipaddress              => '10.1.1.1',
    }
  end

  context 'with defaults' do
    it  do
      [
        'ironic',
        'ironic::api',
        'ironic::conductor',
        'ironic::drivers::ipmi',
        'ironic::keystone::auth'
      ].each do |x|
        should contain_class(x)
      end

      should contain_user('ironic').with(
        {
          :ensure => 'present',
          :before => '[Package[ironic-api]{:name=>"ironic-api"}, Package[ironic-conductor]{:name=>"ironic-conductor"}]',
          :tag    => 'package',
        }
      )

      should contain_file('/var/lib/ironic').with(
          {
            :ensure  => 'directory',
            :owner   => 'ironic',
            :group   => 'ironic',
            :require => 'User[ironic]',
          }
      )

        should contain_file('/tftpboot').with(
          {
            :ensure => 'directory',
            :owner  => 'ironic',
            :group  => 'ironic',
          }
        )

        should contain_file('/tftpboot/pxelinux.cfg').with(
          {
            :ensure => 'directory',
            :owner  => 'ironic',
            :group  => 'ironic',
          }
        )

        should contain_file('/tftpboot/pxelinux.0').with(
          {
            :owner  => 'ironic',
            :group  => 'ironic',
            :source  => '/usr/lib/syslinux/pxelinux.0',
            :require => 'Package[syslinux]'
          }
        )

        should contain_file('/tftpboot/map-file').with(
          {
            :owner  => 'ironic',
            :group  => 'ironic',
            :source => 'puppet:///modules/rjil/tftpd.map-file',
          }
        )

        ['ipmitool','tftpd-hpa','syslinux'].each do |x|
          should contain_package(x).with_ensure('present')
        end

        should contain_ironic_config('conductor/api_url').with_value('http://10.1.1.1:6385/')

        should contain_ironic_config('neutron/url').with_value('http://localhost:9696')

        should contain_rjil__test__check('ironic').with(
          {
            :port => 6385,
            :ssl  => false,
          }
        )

        should contain_rjil__test__check('tftp').with(
          {
            :type       => 'udp',
            :check_type => 'validation',
            :port       => 69
          }
        )

        should contain_rjil__test__check('ironic-conductor').with_type('proc')

        should contain_rjil__jiocloud__consul__service('ironic').with(
          {
            :tags => 'real',
            :port => 6385
          }
        )

        should contain_rjil__jiocloud__consul__service('ironic-conductor').with_tags('real')
    end
  end

end

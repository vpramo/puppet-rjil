##
# Custom fact for ipaddress and interface based on network and netmask
# This will help to configure ipaddress and interfaces for various services
# without assuming IP address on specific interface.
# If the machine have 2 nics with network 192.168.0.0/24 and 10.0.0.0/8, this
# code will create facts like below with appropriate values.
# ipaddress_192_168_0_0_24, interface_192_168_0_0_24,
# ipaddress_10.0.0.0_24, interface_10.0.0.0_24
##
require 'ipaddr'
Facter.value('interfaces').split(',').reject{ |r| r == 'lo' }.each do |iface|
  ipaddress = Facter.value('ipaddress_' + iface)
  if ipaddress
    ##
    # converting netmask to cidr, so that providing fact name would be easier
    # - rather than typing ipaddress_192_168_0_0_255_255_255_0 just type
    # 192_168_0_0_24 (<network>_<cidr>)
    ##
    cidr = IPAddr.new(Facter.value('netmask_' + iface)).to_i.to_s(2).count("1").to_s
    network = Facter.value('network_' + iface).gsub('.', '_')
    Facter.add('ipaddress_' + network + '_' + cidr) do
      setcode do
        ipaddress
      end
    end
    Facter.add('interface_' + network + '_' + cidr) do
      setcode do
        iface
      end
    end
  end
end

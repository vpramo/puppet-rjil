Facter.add(:'ipaddress_br_ctlplane_or_eth0') do
  setcode do
    Facter.value(:'ipaddress_br_ctlplane') || Facter.value(:ipaddress_eth0)
  end
end

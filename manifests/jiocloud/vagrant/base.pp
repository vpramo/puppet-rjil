##
# This is used to install virtualbox and vagrant 
# on the bare metal
class rjil::jiocloud::vagrant::base {
  include virtualbox
  include vagrant
}

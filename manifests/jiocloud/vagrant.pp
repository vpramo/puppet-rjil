# This class is used only for installing
# virtualbox and vagrant
class rjil::jiocloud::vagrant {
  include virtualbox
  include vagrant
}

# Define rjil::system::accounts::sudo::conf
# Purpose
# Generates sudoers files under /etc/sudoers.d/, one per user

define rjil::system::accounts::sudo::conf (
  $user             = $name,
  $commands_allowed = [],
) {

  $user_for_sudo = regsubst($user,'\.','','G')
  $cmdalias_name_uc = upcase($user_for_sudo)

  ##
  # empty array in commands allowed means all commands are allowed (isn't it okay?)
  ##
  if empty($commands_allowed) {
    $sudo_conf = "#Managed By Puppet\n${user} ALL=(ALL) NOPASSWD: ALL"
  } else {
    $commands_allowed_list = join($commands_allowed,',')

    $sudo_conf = "#Managed By Puppet
Cmnd_Alias CMND_${cmdalias_name_uc} = ${commands_allowed_list}
${user} ALL=(ALL) NOPASSWD: CMND_${cmdalias_name_uc}"
  }

  ::sudo::conf { $user:
    content  => $sudo_conf,
  }
}

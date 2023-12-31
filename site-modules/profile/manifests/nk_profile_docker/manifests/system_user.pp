# @summary manage docker group users
#
# @param create_user
#   Boolean to cotrol whether the user should be created
#
define docker::system_user (
  Boolean $create_user = true
) {
  include docker

  $docker_group = $docker::docker_group

  if $create_user {
    ensure_resource('user', $name, { 'ensure' => 'present' })

    User[$name] -> Exec["docker-system-user-${name}"]
  }

  exec { "docker-system-user-${name}":
    command => "/usr/sbin/usermod -aG ${docker_group} ${name}",
    unless  => "/bin/cat /etc/group | grep '^${docker_group}:' | grep -qw ${name}",
  }
}

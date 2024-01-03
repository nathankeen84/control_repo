node default {
#  $default_role = $facts['role']
#  lookup('role', String[1, default], 'first', $default_role).include
}
node 'puppet.k33n0.com' {
  include role::master_server
}
node /^web/ {
  include role::app_server
}
node /^db/ {
  include role::db_server
}
node /dk01.k33n0.com/ {
  include role::docker_server
}

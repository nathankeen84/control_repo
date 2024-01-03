node default {
  file { '/root/README':
    ensure => file,
    content => 'This is a readme',
    owner   => 'root',
  }
}
node 'puppet.k33n0.com': {
  include role::master_server
  file {'/root/README':
    ensure => file,
    content => "Welcome to ${fqdn}",
    owner => 'root',
  }
}
node 'minetest.puppet.vm' {
  include role::minecraft_server
}
node /^web/ { 
  include role::app_server
}
node /^db/ {
  include role::db_server
}

node default {
  file { '/root/README':
    ensure => file,
    content => 'This is a readme',
    owner   => 'root',
  }
}
node 'puppet.k33n0.com': {
  include role::master_server
}
node 'minetest.puppet.vm': {
  include role::minecraft_server
}


node default {
  file { '/root/README':
    ensure  => file,
    content => 'This is a readme',
    owner   => 'root',
  } 
}
node 'ubuntu-22.04' {
  include role::master_server
  file {'/etc/secret_password.txt':
    ensure => file,
    content => lookup('secret_password'),
  }
}
  
node /^web/ {
  include role::app_server
}

node /^db/ {
  include role::db_server
}

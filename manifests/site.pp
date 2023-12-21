node default {
  file { '/root/README.md':
    ensure => file, 
    content => 'This is a readme',
  }
}

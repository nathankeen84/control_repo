class profile::base {
  user {'admin':
    ensure => present,
  include facter  
  }
}

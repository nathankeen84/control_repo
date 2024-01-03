class role::master_server {
  include profile::base
  include profile::facter
  include profile::dockeragent
}

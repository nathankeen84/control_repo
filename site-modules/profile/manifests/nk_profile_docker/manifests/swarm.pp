# @summary
#  managers a Docker Swarm Mode cluster
#
# @param ensure
#  This ensures that the cluster is present or not.
#  Note this forcefully removes a node from the cluster. Make sure all worker nodes
#  have been removed before managers
#
# @param init
#  This creates the first worker node for a new cluster.
#  Set init to true to create a new cluster
#
# @param join
#  This adds either a worker or manger node to the cluster.
#  The role of the node is defined by the join token.
#  Set to true to join the cluster
#
# @param advertise_addr
#  The address that your node will advertise to the cluster for raft.
#  On multihomed servers this flag must be passed
#
# @param autolock
#   Enable manager autolocking (requiring an unlock key to start a stopped manager)
#
# @param cert_expiry
#  Validity period for node certificates (ns|us|ms|s|m|h) (default 2160h0m0s)
#
# @param default_addr_pool
#  Array of default subnet pools for global scope networks (['30.30.0.0/16','40.40.0.0/16'])
#
# @param default_addr_pool_mask_length
#  Default subnet pools mask length for default-addr-pools (CIDR block number)
#
# @param dispatcher_heartbeat
#  Dispatcher heartbeat period (ns|us|ms|s|m|h) (default 5s)
#
# @param external_ca
#  Specifications of one or more certificate signing endpoints
#
# @param force_new_cluster
#  Force create a new cluster from current state
#
# @param listen_addr
#  The address that your node will listen to the cluster for raft.
#  On multihomed servers this flag must be passed
#
# @param max_snapshots
#  Number of additional Raft snapshots to retain
#
# @param snapshot_interval
#  Number of log entries between Raft snapshots (default 10000)
#
# @param token
#  The authentication token to join the cluster. The token also defines the type of
#  node (worker or manager)
#
# @param manager_ip
#  The ip address of a manager node to join the cluster.
#
define docker::swarm (
  Enum[present,absent] $ensure                        = 'present',
  Boolean              $init                          = false,
  Boolean              $join                          = false,
  Optional[String]     $advertise_addr                = undef,
  Boolean              $autolock                      = false,
  Optional[String]     $cert_expiry                   = undef,
  Optional[Array]      $default_addr_pool             = undef,
  Optional[String]     $default_addr_pool_mask_length = undef,
  Optional[String]     $dispatcher_heartbeat          = undef,
  Optional[String]     $external_ca                   = undef,
  Boolean              $force_new_cluster             = false,
  Optional[String]     $listen_addr                   = undef,
  Optional[String]     $max_snapshots                 = undef,
  Optional[String]     $snapshot_interval             = undef,
  Optional[String]     $token                         = undef,
  Optional[String]     $manager_ip                    = undef,
) {
  include docker::params

  if $facts['os']['family'] == 'windows' {
    $exec_environment = "PATH=${facts['docker_program_files_path']}/Docker/"
    $exec_path        = ["${facts['docker_program_files_path']}/Docker/",]
    $exec_timeout     = 3000
    $exec_provider    = 'powershell'
    $unless_init      = '$info = docker info | select-string -pattern "Swarm: active"
                         if ($info -eq $null) { Exit 1 } else { Exit 0 }'
    $unless_join      = '$info = docker info | select-string -pattern "Swarm: active"
                         if ($info -eq $null) { Exit 1 } else { Exit 0 }'
    $onlyif_leave     = '$info = docker info | select-string -pattern "Swarm: active"
                         if ($info -eq $null) { Exit 1 } else { Exit 0 }'
  } else {
    $exec_environment = 'HOME=/root'
    $exec_path        = ['/bin', '/usr/bin',]
    $exec_timeout     = 0
    $exec_provider    = undef
    $unless_init      = 'docker info | grep -w "Swarm: active"'
    $unless_join      = 'docker info | grep -w "Swarm: active"'
    $onlyif_leave     = 'docker info | grep -w "Swarm: active"'
  }

  $docker_command = "${docker::params::docker_command} swarm"

  if $init {
    $docker_swarm_init_flags = docker_swarm_init_flags({
        init                          => $init,
        advertise_addr                => $advertise_addr,
        autolock                      => $autolock,
        cert_expiry                   => $cert_expiry,
        dispatcher_heartbeat          => $dispatcher_heartbeat,
        default_addr_pool             => $default_addr_pool,
        default_addr_pool_mask_length => $default_addr_pool_mask_length,
        external_ca                   => $external_ca,
        force_new_cluster             => $force_new_cluster,
        listen_addr                   => $listen_addr,
        max_snapshots                 => $max_snapshots,
        snapshot_interval             => $snapshot_interval,
      }
    )

    $exec_init = "${docker_command} ${docker_swarm_init_flags}"

    exec { 'Swarm init':
      command     => $exec_init,
      environment => $exec_environment,
      path        => $exec_path,
      provider    => $exec_provider,
      timeout     => $exec_timeout,
      unless      => $unless_init,
    }
  }

  if $join {
    $docker_swarm_join_flags = docker_swarm_join_flags({
        join           => $join,
        advertise_addr => $advertise_addr,
        listen_addr    => $listen_addr,
        token          => $token,
      }
    )

    $exec_join = "${docker_command} ${docker_swarm_join_flags} ${manager_ip}"

    exec { 'Swarm join':
      command     => $exec_join,
      environment => $exec_environment,
      path        => $exec_path,
      provider    => $exec_provider,
      timeout     => $exec_timeout,
      unless      => $unless_join,
    }
  }

  if $ensure == 'absent' {
    exec { 'Leave swarm':
      command  => 'docker swarm leave --force',
      onlyif   => $onlyif_leave,
      path     => $exec_path,
      provider => $exec_provider,
    }
  }
}

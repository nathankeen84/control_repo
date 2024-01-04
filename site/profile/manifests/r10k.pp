class profile::r10k {
  class {'r10k':
    remote => 'git@github.com:nathankeen84/control_repo.git',
  }
}

# @summary
#
# @param location
#
# @param key_source
#
# @param key_check_source
#
# @param architecture
#
class docker::repos (
  Optional[String]  $location         = $docker::package_location,
  Optional[String]  $key_source       = $docker::package_key_source,
  Optional[Boolean] $key_check_source = $docker::package_key_check_source,
  String            $architecture     = $facts['os']['architecture'],
) {
  stdlib::ensure_packages($docker::prerequired_packages)

  case $facts['os']['family'] {
    'Debian': {
      $release       = $docker::release
      $package_key   = $docker::package_key
      $package_repos = $docker::package_repos

      if ($docker::use_upstream_package_source) {
        apt::source { 'docker':
          location     => $location,
          architecture => $architecture,
          release      => $release,
          repos        => $package_repos,
          key          => {
            id     => $package_key,
            source => $key_source,
          },
          include      => {
            src => false,
          },
        }

        $url_split  = split($location, '/')
        $repo_host  = $url_split[2]
        $pin_ensure = $docker::pin_upstream_package_source ? {
          true    => 'present',
          default => 'absent',
        }

        apt::pin { 'docker':
          ensure   => $pin_ensure,
          origin   => $repo_host,
          priority => $docker::apt_source_pin_level,
        }

        if $docker::manage_package {
          include apt

          if (versioncmp($facts['facterversion'], '2.4.6') <= 0) {
            if $facts['os']['name'] == 'Debian' and $facts['os']['lsb']['distcodename'] == 'wheezy' {
              include apt::backports
            }
          } else {
            if $facts['os']['name'] == 'Debian' and $facts['os']['distro']['codename'] == 'wheezy' {
              include apt::backports
            }
          }
          Exec['apt_update']    -> Package[$docker::prerequired_packages]
          Apt::Source['docker'] -> Package['docker']
        }
      }
    }
    'RedHat': {
      if ($docker::manage_package) {
        $baseurl      = $location
        $gpgkey       = $key_source
        $gpgkey_check = $key_check_source

        if ($docker::use_upstream_package_source) {
          yumrepo { 'docker':
            descr    => 'Docker',
            baseurl  => $baseurl,
            gpgkey   => $gpgkey,
            gpgcheck => $gpgkey_check,
          }

          Yumrepo['docker'] -> Package['docker']
        }
      }
    }
    default: {}
  }
}

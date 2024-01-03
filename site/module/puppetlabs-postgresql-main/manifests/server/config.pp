# @api private
class postgresql::server::config {
  postgresql::server::instance::config { 'main':
    ip_mask_deny_postgres_user   => $postgresql::server::ip_mask_deny_postgres_user,
    ip_mask_allow_all_users      => $postgresql::server::ip_mask_allow_all_users,
    listen_addresses             => $postgresql::server::listen_addresses,
    port                         => $postgresql::server::port,
    ipv4acls                     => $postgresql::server::ipv4acls,
    ipv6acls                     => $postgresql::server::ipv6acls,
    pg_hba_conf_path             => $postgresql::server::pg_hba_conf_path,
    pg_ident_conf_path           => $postgresql::server::pg_ident_conf_path,
    postgresql_conf_path         => $postgresql::server::postgresql_conf_path,
    postgresql_conf_mode         => $postgresql::server::postgresql_conf_mode,
    recovery_conf_path           => $postgresql::server::recovery_conf_path,
    pg_hba_conf_defaults         => $postgresql::server::pg_hba_conf_defaults,
    user                         => $postgresql::server::user,
    group                        => $postgresql::server::group,
    version                      => $postgresql::server::_version,
    manage_pg_hba_conf           => $postgresql::server::manage_pg_hba_conf,
    manage_pg_ident_conf         => $postgresql::server::manage_pg_ident_conf,
    manage_recovery_conf         => $postgresql::server::manage_recovery_conf,
    manage_postgresql_conf_perms => $postgresql::server::manage_postgresql_conf_perms,
    datadir                      => $postgresql::server::datadir,
    logdir                       => $postgresql::server::logdir,
    service_name                 => $postgresql::server::service_name,
    service_enable               => $postgresql::server::service_enable,
    log_line_prefix              => $postgresql::server::log_line_prefix,
    timezone                     => $postgresql::server::timezone,
    password_encryption          => $postgresql::server::password_encryption,
    extra_systemd_config         => $postgresql::server::extra_systemd_config,
  }
}
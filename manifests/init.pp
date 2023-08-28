# @summary This module manages SystemD services files
#
# @param units
#   Define the unit parameters.
#
class systemd (
  Hash $units = {},
) {
  exec { 'systemd_reload':
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    path        => '/bin:/usr/bin:/usr/local/bin',
  }

  create_resources('systemd::unit', $units)
}

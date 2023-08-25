# @summary This module manages SystemD services files
#
# @param units
#   Define the unit parameters.
#
class systemd (
  Optional[Hash] $units = undef,
) {
  exec { 'systemd_reload':
    command     => 'systemctl daemon-reload',
    refreshonly => true,
    path        => '/bin:/usr/bin:/usr/local/bin',
  }

  if $units != undef {
    validate_hash($units)

    create_resources('systemd::unit', $units)
  }
}

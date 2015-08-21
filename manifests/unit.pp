# == Class: systemd::unit
#
#
define systemd::unit (
  $ensure                  = 'present',
  $systemd_path            = '/etc/systemd/system',
  $unit_description        = undef,
  $workingdirectory        = undef,
  $user                    = undef,
  $group                   = undef,
  $service_timeoutstartsec = undef,
  $service_execstartpre    = undef,
  $service_execstart       = undef,
  $service_execstop        = undef,
  $install_wantedby        = undef,
) {

  validate_re($ensure, [ '^present$', '^absent$' ],
    "systemd::unit::${name}::ensure is invalid and does not match the regex.")

  validate_absolute_path($systemd_path)

  if $unit_description != undef {
    validate_string($unit_description)
  }
  if $workingdirectory != undef {
    validate_string($workingdirectory)
  }
  if $user != undef {
    validate_string($user)
  }
  if $group != undef {
    validate_string($group)
  }
  if $service_timeoutstartsec != undef {
    validate_integer($service_timeoutstartsec)
  }
  if $service_execstartpre != undef {
    validate_array($service_execstartpre)
  }
  if $service_execstart != undef {
    validate_string($service_execstart)
  }
  if $service_execstop != undef {
    validate_string($service_execstop)
  }
  if $install_wantedby != undef {
    validate_string($install_wantedby)
  }

  file { "${name}_file":
    ensure  => $ensure,
    path    => "${systemd_path}/${name}.service",
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('systemd/systemd_service.erb'),
  }

  exec { 'systemd_reload':
    command     => '/usr/bin/systemctl daemon-reload',
#    refreshonly => true,
  }

  service { "${name}_service":
    ensure   => running,
    name     => $name,
    enable   => true,
    provider => 'systemd',
  }

  File["${name}_file"] -> Exec['systemd_reload'] -> Service["${name}_service"]
}
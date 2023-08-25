# == Class: systemd::unit
#
# @example
#   Define service 'myservice' as a systemd unit.
#
#   systemd::units:
#     'myservice':
#       unit_description: 'This is my service'
#       service_timeoutstartsec: 0
#       service_execstartpre: [ '-/usr/bin/command --kill' , '-/usr/bin/command --rm' ]
#       service_execstart: "/usr/bin/command run --fqdn %{fqdn}"
#       service_execstop: '/usr/bin/command --kill'
#       install_wantedby: 'multi-user.target'
#
# @param ensure
#   Ensure attribute for unit file resource. Valid values are 'present' and 'absent'.
#
# @param systemd_path
#   Path to systemd unit files.
#
# @param unit_after
#   List of units that must be started before the unit being configured.
#
# @param unit_before
#   List of units that must be started after the unit being configured.
#
# @param unit_description
#   A free-form string describing the unit.
#
# @param unit_requires
#   List of units that will be activated as well as the unit being configured.
#
# @param environment
#   Set environment variables for executed processes. Takes a list of space-separated
#   list of variable assignments.
#
# @param group
#   Group running the service.
#
# @param user
#   User running the service.
#
# @param workingdirectory
#   Defines on which directory the service will be launched from.
#
# @param service_type
#   Configures the process start-up type for this service unit.
#   Valid values are: 'simple', 'forking', 'oneshot', 'dbus', 'notify' and 'idle'.
#
# @param service_timeoutstartsec
#   Configures the time to wait for start-up. If a daemon service does not signal start-up
#   completion within the configured time, the service will be considered failed and will
#   be shut down again. Takes a unit-less value in seconds, or a time span value such as
#   "5min 20s".
#
# @param service_restart
#   Configures whether the service shall be restarted when the service process exits,
#   is killed, or a timeout is reached.
#
# @param service_restartsec
#   Configures the time to sleep before restarting a service (as configured with Restart=).
#   Takes a unit-less value in seconds, or a time span value such as "5min 20s".
#
# @param service_execstartpre
#   Additional commands that are executed before the command in service_execstart.
#
# @param service_execstart
#   Commands with their arguments that are executed when this service is started.
#
# @param service_execstop
#   Commands to execute to stop the service started via service_execstart.
#
# @param install_wantedby
#   The most common way to specify how a unit should be enabled. This directive allows you
#   to specify a dependency relationship in a similar way to the Wants= directive does in
#   the [Unit] section.
#
define systemd::unit (
  Enum['present', 'absent'] $ensure               = 'present',
  Stdlib::Absolutepath $systemd_path              = '/etc/systemd/system',
  Optional[String[1]] $unit_after                 = undef,
  Optional[String[1]] $unit_before                = undef,
  Optional[String[1]] $unit_description           = undef,
  Optional[String[1]] $unit_requires              = undef,
  Optional[String[1]] $environment                = undef,
  Optional[String[1]] $group                      = undef,
  Optional[String[1]] $user                       = undef,
  Optional[String[1]] $workingdirectory           = undef,
  Systemd::Service_type $service_type             = 'simple',
  Optional[Systemd::Sec] $service_timeoutstartsec = undef,
  Optional[String[1]] $service_restart            = undef,
  Optional[Systemd::Sec]  $service_restartsec     = undef,
  Optional[Array] $service_execstartpre           = undef,
  Optional[String[1]] $service_execstart          = undef,
  Optional[String[1]] $service_execstop           = undef,
  Optional[String[1]] $install_wantedby           = undef,
) {
  include systemd

  file { "${name}_file":
    ensure  => $ensure,
    path    => "${systemd_path}/${name}.service",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('systemd/systemd_service.erb'),
  }

  service { "${name}_service":
    ensure   => running,
    name     => $name,
    enable   => true,
    provider => 'systemd',
  }

  File["${name}_file"] ~> Exec['systemd_reload'] -> Service["${name}_service"]
}

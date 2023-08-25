# Data type for valid service_type values used by systemd
type Systemd::Service_type = Enum[
  'simple',
  'forking',
  'oneshot',
  'dbus',
  'notify',
  'idle'
]

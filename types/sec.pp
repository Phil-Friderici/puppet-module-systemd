# Data type for valid time values used by systemd
type Systemd::Sec = Variant[
  Integer[0],
  Enum['infinity'],
  Pattern['(([0-9]+h(our)?)?([0-9]+m(in)?)?([0-9]+s(ec)?([0-9]+ms)?)?)'],
]

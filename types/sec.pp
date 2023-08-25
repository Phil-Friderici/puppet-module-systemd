# Data type for valid time values used by systemd
type Systemd::Sec = Variant[
  Integer[0],
  Enum['infinity'],
  Pattern['^[0-9]+$'],                              # stringified positive integers
  Pattern['^([0-9]+(ms|sec|s|min|m|hour|h)( )?)+'], # '3ms', '3s', '3sec', '3m', '3min', '3h', '3hour', '4h 2m' etc etc
]

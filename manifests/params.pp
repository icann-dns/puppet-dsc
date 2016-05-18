# dsc::params
#
class dsc::params {

  $ip_addresses = [$::ipaddress]
  $listen_interfaces = split($::interfaces, ',')

  $package = $::kernel ? {
    'FreeBSD' => 'dsc-collector',
    default => 'dsc-statistics-collector',
  }
  $conf_file = $::kernel ? {
    'FreeBSD' => '/usr/local/etc/dsc.conf',
    default => '/etc/dsc-statistics/dsc-collector.cfg',
  }
  $service = $::kernel ? {
    'FreeBSD' => 'dsc',
    default => 'dsc-statistics-collector',
  }
}

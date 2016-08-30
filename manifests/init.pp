# Class: dsc
#
class dsc (
  $prefix            = '/usr/local/dsc',
  $ip_addresses      = $dsc::params::ip_addresses,
  $custom_dataset    = [],
  $bpf_program       = false,
  $listen_interfaces = $dsc::params::listen_interfaces,
  $package           = $dsc::params::package,
  $conf_file         = $dsc::params::conf_file,
  $service           = $dsc::params::service,
  $pid_file          = '/var/run/dsc-statistics-collector/default/dsc.pid',
  $max_memory        = 4194304,
  $presenter         = 'dsp'
) inherits dsc::params {

  validate_absolute_path($prefix)
  validate_array($ip_addresses)
  validate_array($custom_dataset)
  validate_bool($bpf_program)
  validate_array($listen_interfaces)
  validate_string($package)
  validate_absolute_path($conf_file)
  validate_string($service)
  validate_absolute_path($pid_file)
  validate_integer($max_memory)
  validate_re($presenter, ['^(dsp|hedgehog)$'])

  #im not sure we need the group any more
  $group = $::kernel ? {
    'FreeBSD' => 'www',
    default   => 'www-data',
  }
  ensure_packages([$package])

  file {
    $prefix:
      ensure => directory,
      group  => $group,
      mode   => '0755';
    "${prefix}/run/":
      ensure => directory;
    "${prefix}/run/${::hostname}":
      ensure => directory;
    "${prefix}/run/${::hostname}/upload":
      ensure => directory;
    "${prefix}/run/${::hostname}/upload/${presenter}":
      ensure => directory;
  }
  file {$conf_file:
    ensure  => present,
    require => Package[$package],
    content => template('dsc/etc/dsc-statistics/dsc-collector.cfg.erb');
  }
  file {'/usr/local/bin/upload_prep':
    ensure  => present,
    mode    => '0755',
    content => template('dsc/usr/local/bin/upload_prep.erb'),
  }

  if $::kernel == 'FreeBSD' {
    ensure_packages(['devel/p5-Proc-PID-File'])
    file{"/usr/local/etc/rc.d/${service}":
      ensure  => present,
      content => template('dsc/usr/local/etc/rc.d/dsc.erb'),
      mode    => '0555',
      before  => Service[$service],
    }
  } else {
    #remove cronjob added by dsc package
    file {'/etc/cron.d/dsc-statistics-collector':
      ensure => absent,
    }
    file {'/etc/init.d/dsc-statistics-collector':
      ensure  => present,
      content => 'echo "Use upstart"',
      mode    => '0555',
      before  => Service[$service],
    }
    file {"/etc/init/${service}.conf":
      ensure  => present,
      content => template('dsc/etc/init/dsc-statistics-collector.conf.erb'),
      before  => Service[$service],
    }
  }
  service {$service:
    ensure    => running,
    enable    => true,
    require   => [
        File[$conf_file,
          "${prefix}/run/${::hostname}/upload/${presenter}"],
        Package[$package],
    ],
    subscribe => [
        File[$conf_file],
        Package[$package],
    ];
  }
  cron { 'upload_prep':
    ensure  => present,
    command => '/usr/bin/flock -n /var/lock/upload_prep.lock /usr/local/bin/upload_prep',
    user    => root,
    minute  => '*/5',
    require => File['/usr/local/bin/upload_prep'];
  }
}

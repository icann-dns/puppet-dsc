# Class: dsc
#
class dsc (
  Optional[Array[String]] $custom_dataset = undef,
  Stdlib::Absolutepath $prefix = '/usr/local/dsc',
  Array[Stdlib::Compat::Ip_address] $ip_addresses = $::dsc::params::ip_addresses,
  Boolean $bpf_program = false,
  Array[String] $listen_interfaces = $::dsc::params::listen_interfaces,
  String $package = $dsc::params::package,
  Stdlib::Absolutepath $conf_file = $::dsc::params::conf_file,
  String $service = $dsc::params::service,
  Stdlib::Absolutepath $pid_file = '/var/run/dsc-statistics-collector/default/dsc.pid',
  Integer $max_memory = 4194304,
  Enum['dsp', 'hedgehog'] $presenter = 'dsp',
  String $sub_folder = $::hostname,
) inherits dsc::params {

  # im not sure we need the group any more
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
    "${prefix}/run/${sub_folder}":
      ensure => directory;
    "${prefix}/run/${sub_folder}/upload":
      ensure => directory;
    "${prefix}/run/${sub_folder}/upload/${presenter}":
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
    if $::lsbdistcodename == 'trusty' {
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
    } else {
      file {"/lib/systemd/system/${service}.service":
        ensure  => present,
        content => template('dsc/lib/systemd/system/dsc-statistics-collector.service.erb'),
        before  => Service[$service],
      }~> exec { 'dsc-systemd-reload':
        command     => 'systemctl daemon-reload',
        path        => [ '/bin', ],
        refreshonly => true,
      }
    }
  }
  service {$service:
    ensure    => running,
    enable    => true,
    require   => [
        File[$conf_file,
          "${prefix}/run/${sub_folder}/upload/${presenter}"],
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

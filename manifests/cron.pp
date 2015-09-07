# manifests/cron.pp
class yum::cron (
  $yum_parameter = undef,
  $check_only = false,
  $check_first = true,
  $download_only = false,
  $randomwait = 60,
  $mailto = 'root',
  $days_of_week = '0123456',
  $cleanday = '0',
  $service_waits = true,
  $service_wait_time = 300,
  $ensure = present
) {
  # validate parameters
  validate_string($yum_parameter, $mailto)
  validate_bool($check_only, $check_first, $download_only, $service_waits)
  validate_integer($randomwait, 9999999, 0)
  validate_integer($service_wait_time, 9999999, 0)
  validate_re($days_of_week, '^[0-6][0-6]*$')
  validate_re($cleanday, '^[0-6][0-6]*$')
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = '/etc/sysconfig/yum-cron'

  # package management
  package {
    'yum-cron' :
      ensure => $ensure ;
  }

  # create configuration file
  file {
    $cfgfile :
      ensure => $ensure,
      content => template('yum/yum-cron.erb'),
      owner => 'root',
      group => 'root',
      mode => '0644' ;
  }

  if $ensure == present {
    # configure service
    service {
      'yum-cron' :
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        require => [File[$cfgfile], Package['yum-cron']] ;
    }
  }
}

class yum (
  $excludes = []
) inherits yum::params {
  # validate parameters
  validate_array($excludes)

  # package management
  package {
    ['yum', 'yum-priorities', 'centos-release', 'yum-versionlock', 'yum-utils'] :
      ensure => present,
      require => undef ;
  }
  case $::operatingsystemmajrelease {
    6 : {
      Package['yum-priorities']{
        name => 'yum-plugin-priorities'
      }
      Package['yum-versionlock']{
        name => 'yum-plugin-versionlock'
      }
    }
  }

  # remove unused kernels
  cron {
    'yum_remove_unused_kernels' :
      command => 'yum -y remove $(rpm -qa kernel | grep -v $(uname -r) | grep -v $(rpm -q --last kernel | cut -d" " -f1 | head -1)) &>/dev/null',
      user => 'root',
      minute => 11,
      hour => 2 ;
  }

  # ensure there are no other repos
  File {
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Package['yum', 'yum-priorities', 'centos-release'],
  }
  file {
    $cfgddir :
      ensure => directory,
      backup => false,
      recurse => true,
      purge => true,
      force => true ;

    $cfgfile :
      content => template('yum/yum.conf.erb'),
      backup => false ;
  }
}

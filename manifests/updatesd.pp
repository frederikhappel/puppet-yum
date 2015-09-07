# manifests/updatesd.pp
class yum::updatesd (
  $ensure = present
) {
  # validate parameters
  validate_re($ensure, '^(present|absent)$')

  # package management
  package {
    'yum-updatesd' :
      ensure => $ensure ;
  }

  if $ensure == present {
    # configure service
    service {
      'yum-updatesd' :
        ensure => running,
        enable => true,
        require => Package['yum-updatesd'] ;
    }
  }
  cron {
    'yumUpdatesd_remove_unused_kernels' :
      ensure => $ensure,
      command => 'yum -y remove $(rpm -qa kernel | grep -v $(uname -r) | grep -v $(rpm -q --last kernel | cut -d" " -f1 | head -1)) &>/dev/null',
      user => 'root',
      minute => 11,
      hour => 2 ;
  }
}

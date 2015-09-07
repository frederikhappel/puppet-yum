define yum::mirror::reposync (
  $baseurl,
  $reponame = $name,
  $descr = undef,
  $gpgcheck = false,
  $gpgkey = undef,
  $download_comps = false,
  $download_newest_only = true,
  $delete_nonexistent = false,
  $mailto = 'root',
  $archs = [$::architecture],
  $releases = [],
  $workers = $::processorcount,
  $ensure = present,
) {
  # validate parameters
  validate_string($baseurl, $reponame, $descr, $gpgkey, $mailto)
  validate_bool(
    $gpgcheck, $download_comps, $download_newest_only, $delete_nonexistent,
  )
  validate_integer($workers)
  validate_array($archs, $releases)
  validate_re($ensure, '^(present|absent)$')

  # define variable
  $cfgfile = "${yum::mirror::params::cfgdir}/${name}.cfg"
  $baseurl_real = regsubst(regsubst($baseurl, '\$basearch', '%ARCH%'), '\$releasever', '%RELEASE%')

  # manage config files
  file {
    $cfgfile :
      ensure => $ensure,
      content => template('yum/reposync-mirror.cfg.erb') ;
  }

  # establish cron job
  cron {
    "yumMirrorReposync_${name}" :
      command => "${yum::mirror::params::reposyncscript} ${cfgfile}",
      user => root,
      hour => 0,
      minute => 30,
      require => Package['yum-utils'] ;
  }
}

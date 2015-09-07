define yum::repo (
  $descr = absent,
  $baseurl = absent,
  $mirrorlist = absent,
  $enabled = 0,
  $gpgcheck = 0,
  $gpgkey = absent,
  $failovermethod = absent,
  $priority = 99,
  $exclude = absent,
  $includepkgs = absent,
  $ensure = present
) {
  # validate parameters
  if !is_string($baseurl) and !is_array($baseurl) {
    fail('$baseurl needs to be of type String or Array')
  }
  validate_string($descr, $mirrorlist, $gpgkey, $failovermethod, $exclude, $includepkgs)
  validate_integer($enabled, 1, 0)
  validate_integer($gpgcheck, 1, 0)
  validate_integer($priority, 99, 1)
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = "${yum::params::cfgddir}/${name}.repo"
  $baseurl_real = flatten([$baseurl])

  # create exec for refreshing all repositories
  exec {
    "yumRepoRefresh_${name}" :
      command => 'yum clean all',
      refreshonly => true,
      require => Package['yum'] ;
  }

  file {
    $cfgfile :
      ensure => $ensure ? { present => file, default => absent },
      replace => true,
      owner => 'root',
      group => 'root',
      mode => '0644',
      require => Package['yum'] ;
  }

  if $ensure != absent {
    yumrepo {
      $name:
        descr => $descr,
        baseurl => join($baseurl_real, ' '),
        mirrorlist => $mirrorlist,
        enabled => $enabled,
        gpgcheck => $gpgcheck,
        gpgkey => $gpgkey,
        failovermethod => $failovermethod,
        priority => $priority,
        exclude => $exclude,
        includepkgs => $includepkgs,
        target => $cfgfile,
        require => File[$cfgfile],
        notify => Exec["yumRepoRefresh_${name}"] ;
    }
  }
}

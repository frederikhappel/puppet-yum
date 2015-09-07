class yum::mirror (
  $pkgdir = $yum::mirror::params::default_pkgdir,
  $ensure = present
) inherits yum::mirror::params {
  # validate parameters
  validate_absolute_path($pkgdir)
  validate_re($ensure, '^(present|absent)$')

  # package management
  package {
    'createrepo' :
      ensure => $ensure;
  }

  case $ensure {
    present : {
      File {
        owner => 0,
        group => 0,
      }
      file {
        [$cfgdir, $datadir] :
          ensure => directory,
          recurse => true,
          purge => true ;

        $pkgdir :
          ensure => directory ;

        $pkgsfile :
          source => 'puppet:///modules/yum/mixed.packages',
          mode => '0644' ;

        $centosscript :
          source => 'puppet:///modules/yum/updatecentos.sh',
          mode => '0755' ;

        $releasescript :
          source => 'puppet:///modules/yum/updaterelease.sh',
          mode => '0755' ;

        $mixedscript :
          source => 'puppet:///modules/yum/updatemixed.sh',
          mode => '0755' ;

        $reposyncscript :
          source => 'puppet:///modules/yum/reposync.sh',
          mode => '0755' ;
      }
    }

    absent : {
      file {
        # remove leftovers but leave downloaded packages
        [$cfgdir, $datadir, $centosscript, $mixedscript, $reposyncscript] :
          ensure => absent,
          recurse => true,
          force => true ;
      }
    }
  }
}

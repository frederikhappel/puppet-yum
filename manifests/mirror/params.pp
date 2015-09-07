class yum::mirror::params {
  # files and directories
  $cfgdir = '/etc/updaterepo'
  $datadir = '/usr/share/updaterepo'
  $default_pkgdir = '/var/www/rpmrepo'

  $pkgsfile = "${cfgdir}/mixed.packages"
  $centosscript = "${datadir}/updatecentos.sh"
  $releasescript = "${datadir}/updaterelease.sh"
  $mixedscript = "${datadir}/updatemixed.sh"
  $reposyncscript = "${datadir}/reposync.sh"
}

define yum::versionedpackage (
  $package_name = $title,
  $append_version = false,
  $version = present,
  $ensure = present
) {
  # validate parameters
  validate_string($package_name, $version)
  validate_bool($append_version)
  validate_re($ensure, '^(present|installed|absent|purged|held|latest)$')

  # define variables
  $epoch_match = '[0-9][0-9]*'
  $package_name_versioned = "${package_name}-${version}"

  if $ensure =~ /^(absent|purged)$/ or $version =~ /^(|present|installed|absent|purged|held|latest)$/ {
    $remove_only = true
  } else {
    $remove_only = false
  }

  # versionlock only working for centos 6+
  if $::operatingsystemmajrelease > 5 {
    # remove versionlock if version changes
    exec {
      "yumPackage_deleteVersionlock_${title}" :
        command => "yum versionlock list | grep '${epoch_match}:${package_name}-[0-9]' | xargs yum versionlock delete",
        onlyif => "yum versionlock list | grep '${epoch_match}:${package_name}-[0-9]'",
        unless => $remove_only ? {
          true => undef,
          default => "yum versionlock list | grep '${epoch_match}:${package_name_versioned}'",
        },
        before => Package[$title] ;
    }
    # add versionlock if version changed
    if !$remove_only {
      exec {
        "yumPackage_addVersionlock_${title}" :
          command => "yum versionlock add ${package_name_versioned}",
          unless => "yum versionlock list | grep '${epoch_match}:${package_name_versioned}'",
          require => Package[$title] ;
      }
    }
  }

  # package management
  package {
    $title :
      ensure => $ensure ? {
        absent => absent,
        default => $version
      },
      name => $append_version ? {
        true => $package_name_versioned,
        default => $package_name
      } ;
  }
}

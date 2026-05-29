# installs and configures vsftpd
class vsftpd (
  # refer to data/common.yaml for default definitions
  Enum['present', 'absent'] $ensure = 'present',
  String[1] $package_name            = 'vsftpd',
  Stdlib::Absolutepath $config_path  = '/etc/vsftpd.conf',
  String[1] $service_name            = 'vsftpd',
  Enum['running', 'stopped'] $service_ensure = 'running',
  Boolean $service_enable            = true,
  Boolean $anonymous_enable          = false,
  Boolean $local_enable              = true,
  Boolean $write_enable              = true,
  String[1] $local_umask             = '022',
  Boolean $dirmessage_enable         = true,
  Boolean $use_localtime             = true,
  Boolean $xferlog_enable            = true,
  Boolean $connect_from_port_20      = true,
  Boolean $chroot_local_user         = true,
  Stdlib::Absolutepath $secure_chroot_dir = '/var/run/vsftpd/empty',
  String[1] $pam_service_name        = 'vsftpd',
  String[1] $ssl_ciphers             = 'HIGH',
  Boolean $ssl_enable                = false,
  Optional[Stdlib::Absolutepath] $rsa_cert_file        = undef,
  Optional[Stdlib::Absolutepath] $rsa_private_key_file = undef,
) {
  # uninstall with vsftpd::ensure: 'absent'
  if $ensure == 'absent' {
    service { $service_name:
      ensure => stopped,
      enable => false,
    }

    file { $config_path:
      ensure => absent,
    }

    package { $package_name:
      ensure => absent,
    }
  # install with vsftpd::ensure: 'present' or any other value
  } else {
    package { $package_name:
      ensure => installed,
    }

    file { $config_path:
      ensure  => file,
      content => template('vsftpd/vsftpd.conf.erb'),
      notify  => Service[$service_name],
    }

    service { $service_name:
      ensure    => $service_ensure,
      enable    => $service_enable,
      require   => Package[$package_name],
      subscribe => File[$config_path],
    }
  }
}

class vsftpd {
  package { 'vsftpd':
    ensure => installed,
  }

  service { 'vsftpd':
    ensure    => running,
    enable    => true,
    require   => Package['vsftpd'],
    subscribe => File['/etc/vsftpd.conf'],
  }

  file { '/etc/vsftpd.conf':
    ensure  => file,
    content => template('vsftpd/vsftpd.conf.erb'),
    notify  => Service['vsftpd'],
  }
}

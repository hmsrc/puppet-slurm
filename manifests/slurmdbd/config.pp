# Private class
class slurm::slurmdbd::config {

  if $slurm::manage_database {
    if $slurm::use_remote_database {
      @@mysql::db { "slurmdbd_${::fqdn}":
        user     => $slurm::slurmdbd_storage_user,
        password => $slurm::slurmdbd_storage_pass,
        dbname   => $slurm::slurmdbd_storage_loc,
        host     => $::fqdn,
        grant    => ['ALL'],
        tag      => $::domain,
      }
    } else {
      include mysql::server

      mysql::db { $slurm::slurmdbd_storage_loc:
        user     => $slurm::slurmdbd_storage_user,
        password => $slurm::slurmdbd_storage_pass,
        host     => $slurm::slurmdbd_storage_host,
        grant    => ['ALL'],
      }
    }
  }

  file { 'slurmdbd.conf':
    ensure  => 'file',
    path    => $slurm::slurmdbd_conf_path,
    owner   => $slurm::slurm_user,
    group   => $slurm::slurm_user_group,
    mode    => '0600',
    content => template('slurm/slurmdbd/slurmdbd.conf.erb'),
    notify  => Service['slurmdbd'],
  }

  file { 'SlurmDBDArchive':
    ensure => 'directory',
    path   => $slurm::slurmdbd_archive_dir,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    include ::systemd
    augeas { 'slurmdbd.service':
      context => "${slurm::slurm_augeas_systemd_dir}/slurmdbd.service",
      changes => [
        "set Unit/ConditionPathExists/value ${slurm::slurmdbd_conf_path}",
        "set Service/PIDFile/value ${slurm::pid_dir}/slurmdbd.pid",
      ],
      notify  => Service['slurmdbd'],
    }
    ~> Exec['systemctl-daemon-reload']
  }

  if $slurm::manage_logrotate {
    #Refer to: http://slurm.schedmd.com/slurm.conf.html#SECTION_LOGGING
    logrotate::rule { 'slurmdbd':
      path          => $slurm::slurmdbd_log_file,
      compress      => true,
      missingok     => true,
      copytruncate  => false,
      delaycompress => false,
      ifempty       => false,
      dateext       => true,
      rotate        => '10',
      sharedscripts => true,
      size          => '10M',
      create        => true,
      create_mode   => '0640',
      create_owner  => $slurm::slurm_user,
      create_group  => 'root',
      prerotate     => $slurm::_logrotate_slurm_prerotate,
      postrotate    => $slurm::_logrotate_slurmdbd_postrotate,
    }
  }

}

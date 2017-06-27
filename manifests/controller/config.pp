# Private class
class slurm::controller::config {

  file { 'StateSaveLocation':
    ensure  => 'directory',
    path    => $slurm::state_save_location,
    owner   => $slurm::slurm_user,
    group   => $slurm::slurm_user_group,
    mode    => '0700',
    require => File[$slurm::shared_state_dir],
  }

  file { 'JobCheckpointDir':
    ensure  => 'directory',
    path    => $slurm::job_checkpoint_dir,
    owner   => $slurm::slurm_user,
    group   => $slurm::slurm_user_group,
    mode    => '0700',
    require => File[$slurm::shared_state_dir],
  }

  #file { 'SlurmConfNFSLocation':
  #  ensure => 'directory',
  #  path   => $slurm::slurm_conf_nfs_location,
  #  owner  => 'root',
  #  group  => 'root',
  #  mode   => '0755',
  #  require => File[$slurm::shared_state_dir],
  #}

  if $slurm::manage_slurm_conf {

    file { 'NFS slurm.conf':
      ensure  => 'present',
      path    => "${slurm::slurm_conf_nfs_location}/slurm.conf",
      content => $slurm::slurm_conf_content,
      source  => $slurm::slurm_conf_source,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      #require => File['SlurmConfNFSLocation'],
    }

    file { 'NFS slurm-partitions.conf':
      ensure  => 'present',
      path    => "${slurm::slurm_conf_nfs_location}/partitions.conf",
      content => $slurm::partitionlist_content,
      source  => $slurm::partitionlist_source,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      #require => File['SlurmConfNFSLocation'],
    }

    if $slurm::node_source {
      file { 'slurm-nodes.conf':
        ensure => 'present',
        path   => "${slurm::slurm_conf_nfs_location}/nodes.conf",
        source => $slurm::node_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        #require => File['SlurmConfNFSLocation'],
      }
    } else {
      datacat { 'slurm-nodes.conf':
        ensure   => 'present',
        path     => "${slurm::slurm_conf_nfs_location}/nodes.conf",
        template => 'slurm/slurm.conf/nodes.conf.erb',
        owner    => 'root',
        group    => 'root',
        mode     => '0644',
        #require => File['SlurmConfNFSLocation'],
      }

      Datacat_fragment <<| tag == $slurm::slurm_nodelist_tag |>>
    }

    file { 'Link slurm.conf':
      ensure  => 'link',
      path    => $slurm::slurm_conf_path,
      target  => "${slurm::slurm_conf_nfs_location}/slurm.conf",
      require => File['NFS slurm.conf'],
    }

    file { 'Link slurm-partitions.conf':
      ensure  => 'link',
      path    => $slurm::partition_conf_path,
      target  => "${slurm::slurm_conf_nfs_location}/partitions.conf",
      require => File['NFS slurm-partitions.conf'],
    }

    file { 'Controller Link slurm-nodes.conf':
      ensure  => 'link',
      path    => $slurm::node_conf_path,
      target  => "${slurm::slurm_conf_nfs_location}/nodes.conf",
      require => File['slurm-nodes.conf'],
    }

  }

  if $slurm::manage_state_dir_nfs_mount {
    mount { 'StateSaveLocation':
      ensure  => 'mounted',
      name    => $slurm::state_save_location,
      atboot  => true,
      device  => $slurm::state_dir_nfs_device,
      fstype  => 'nfs',
      options => $slurm::state_dir_nfs_options,
      require => File['StateSaveLocation'],
    }
  }

  if $slurm::manage_job_checkpoint_dir_nfs_mount {
    mount { 'JobCheckpointDir':
      ensure  => 'mounted',
      name    => $slurm::job_checkpoint_dir,
      atboot  => true,
      device  => $slurm::job_checkpoint_dir_nfs_device,
      fstype  => 'nfs',
      options => $slurm::job_checkpoint_dir_nfs_options,
      require => File['JobCheckpointDir'],
    }
  }

  if $slurm::manage_scripts {
    if $slurm::manage_job_comp and $slurm::job_comp {
      if '*' in $slurm::job_comp {
        file { 'job_comp':
          ensure       => 'directory',
          path         => dirname($slurm::job_comp),
          source       => $slurm::job_comp_source,
          owner        => 'root',
          group        => 'root',
          mode         => '0755',
          recurse      => true,
          recurselimit => 1,
          purge        => true,
        }
      } else {
        file { 'job_comp':
          ensure => 'file',
          path   => $slurm::job_comp,
          source => $slurm::job_comp_source,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
    }

    if $slurm::manage_slurmctld_prolog and $slurm::slurmctld_prolog {
      if '*' in $slurm::slurmctld_prolog {
        file { 'slurmctld_prolog':
          ensure       => 'directory',
          path         => dirname($slurm::slurmctld_prolog),
          source       => $slurm::slurmctld_prolog_source,
          owner        => 'root',
          group        => 'root',
          mode         => '0755',
          recurse      => true,
          recurselimit => 1,
          purge        => true,
        }
      } else {
        file { 'slurmctld_prolog':
          ensure => 'file',
          path   => $slurm::slurmctld_prolog,
          source => $slurm::slurmctld_prolog_source,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
    }

    if $slurm::manage_job_submit_plugin and $slurm::job_submit_plugin_lua_source {
      file { 'job_submit_lua':
        ensure => 'file',
        path   => '/etc/slurm/job_submit.lua',
        source => $slurm::job_submit_plugin_lua_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }
  }

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    include ::systemd
    augeas { 'slurmctld.service':
      context => "${slurm::slurm_augeas_systemd_dir}/slurmctld.service",
      changes => [
        "set Unit/ConditionPathExists/value ${slurm::slurm_conf_path}",
        "set Service/PIDFile/value ${slurm::pid_dir}/slurmctld.pid",
      ],
      notify  => Service['slurmctld'],
    }
    ~> Exec['systemctl-daemon-reload']
  }

  if $slurm::manage_logrotate {
    #Refer to: http://slurm.schedmd.com/slurm.conf.html#SECTION_LOGGING
    logrotate::rule { 'slurmctld':
      path          => $slurm::slurmctld_log_file,
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
      postrotate    => $slurm::_logrotate_slurmctld_postrotate,
    }
  }

}

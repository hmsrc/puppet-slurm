# Private class
class slurm::node::config {

  if $slurm::manage_cgroup_release_agents {
    file { $slurm::cgroup_release_agent_dir_real:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_blkio":
      ensure => 'link',
      target => 'release_common',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_cpuacct":
      ensure => 'link',
      target => 'release_common',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_cpuset":
      ensure => 'link',
      target => 'release_common',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_freezer":
      ensure => 'link',
      target => 'release_common',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_memory":
      ensure => 'link',
      target => 'release_common',
    }
    -> file { "${slurm::cgroup_release_agent_dir_real}/release_devices":
      ensure => 'link',
      target => 'release_common',
    }
  }

  if $slurm::manage_cgroup_release_agents and $release == '16.05' {
    file { "${slurm::cgroup_release_agent_dir_real}/release_common":
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => $slurm::cgroup_release_common_source_real,
    }
  }

  if $slurm::manage_scripts {
    if $slurm::manage_epilog and $slurm::epilog {
      if '*' in $slurm::epilog {
        file { 'epilog':
          ensure       => 'directory',
          path         => dirname($slurm::epilog),
          source       => $slurm::epilog_source,
          owner        => 'root',
          group        => 'root',
          mode         => '0755',
          recurse      => true,
          recurselimit => 1,
          purge        => true,
        }
      } else {
        file { 'epilog':
          ensure => 'file',
          path   => $slurm::epilog,
          source => $slurm::epilog_source,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
    }

    if $slurm::manage_prolog and $slurm::prolog {
      if '*' in $slurm::prolog {
        file { 'prolog':
          ensure       => 'directory',
          path         => dirname($slurm::prolog),
          source       => $slurm::prolog_source,
          owner        => 'root',
          group        => 'root',
          mode         => '0755',
          recurse      => true,
          recurselimit => 1,
          purge        => true,
        }
      } else {
        file { 'prolog':
          ensure => 'file',
          path   => $slurm::prolog,
          source => $slurm::prolog_source,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
      }
    }

    if $slurm::manage_task_epilog and $slurm::task_epilog {
      file { 'task_epilog':
        ensure => 'file',
        path   => $slurm::task_epilog,
        source => $slurm::task_epilog_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }

    if $slurm::manage_task_prolog and $slurm::task_prolog {
      file { 'task_prolog':
        ensure => 'file',
        path   => $slurm::task_prolog,
        source => $slurm::task_prolog_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }

    if $slurm::manage_health_check and $slurm::health_check_program {
      file { 'health_check':
        ensure => 'file',
        path   => $slurm::health_check_program,
        source => $slurm::health_check_program_source,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }
  }

  if $::gpu_node == 'true' {
    file { '/etc/slurm/gres.conf':
      content => template('slurm/gres/gres.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  file { 'SlurmdSpoolDir':
    ensure => 'directory',
    path   => $slurm::slurmd_spool_dir,
    owner  => $slurm::slurmd_user,
    group  => $slurm::slurmd_user_group,
    mode   => '0755',
  }

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    include ::systemd
    augeas { 'slurmd.service':
      context => "${slurm::slurm_augeas_systemd_dir}/slurmd.service",
      changes => [
        "set Unit/ConditionPathExists/value ${slurm::slurm_conf_path}",
        "set Service/PIDFile/value ${slurm::pid_dir}/slurmd.pid",
      ],
      notify  => Service['slurmd'],
    }
    ~> Exec['systemctl-daemon-reload']
  }

  if $slurm::manage_logrotate {
    #Refer to: http://slurm.schedmd.com/slurm.conf.html#SECTION_LOGGING
    logrotate::rule { 'slurmd':
      path          => $slurm::slurmd_log_file,
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
      create_owner  => $slurm::slurmd_user,
      create_group  => 'root',
      prerotate     => $slurm::_logrotate_slurm_prerotate,
      postrotate    => $slurm::_logrotate_slurm_postrotate,
    }
  }

}

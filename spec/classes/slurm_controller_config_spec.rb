require 'spec_helper'

describe 'slurm::controller::config' do
  let(:facts) { default_facts }

  let(:pre_condition) { "class { 'slurm': }" }

  it { should create_class('slurm::controller::config') }
  it { should contain_class('slurm') }

  it do
    should contain_file('StateSaveLocation').with({
      :ensure   => 'directory',
      :path     => '/var/lib/slurm/state',
      :owner    => 'slurm',
      :group    => 'slurm',
      :mode     => '0700',
      :require  => 'File[/var/lib/slurm]',
    })
  end

  it do
    should contain_file('JobCheckpointDir').with({
      :ensure   => 'directory',
      :path     => '/var/lib/slurm/checkpoint',
      :owner    => 'slurm',
      :group    => 'slurm',
      :mode     => '0700',
      :require  => 'File[/var/lib/slurm]',
    })
  end

  it { should_not contain_mount('StateSaveLocation') }
  it { should_not contain_mount('JobCheckpointDir') }

  it do
    should contain_logrotate__rule('slurmctld').with({
      :path          => '/var/log/slurm/slurmctld.log',
      :compress      => 'true',
      :missingok     => 'true',
      :copytruncate  => 'false',
      :delaycompress => 'false',
      :ifempty       => 'false',
      :rotate        => '10',
      :sharedscripts => 'true',
      :size          => '10M',
      :create        => 'true',
      :create_mode   => '0640',
      :create_owner  => 'slurm',
      :create_group  => 'root',
      :postrotate    => '/etc/init.d/slurm reconfig >/dev/null 2>&1',
    })
  end

  context 'when manage_logrotate => false' do
    let(:params) {{ :manage_logrotate => false }}
    it { should_not contain_logrotate__rule('slurmctld') }
  end

  context 'when manage_state_dir_nfs_mount => true' do
    let(:params) {{ :manage_state_dir_nfs_mount => true }}

    it do
      should contain_mount('StateSaveLocation').with({
        :ensure   => 'mounted',
        :name     => '/var/lib/slurm/state',
        :atboot   => 'true',
        :device   => nil,
        :fstype   => 'nfs',
        :options  => 'rw,sync,noexec,nolock,auto',
        :require  => 'File[StateSaveLocation]',
      })
    end

    context 'when state_dir_nfs_device => "192.168.1.1:/slurm/state"' do
      let(:params) {{ :manage_state_dir_nfs_mount => true, :state_dir_nfs_device => '192.168.1.1:/slurm/state' }}
      it { should contain_mount('StateSaveLocation').with_device('192.168.1.1:/slurm/state') }
    end

    context 'when state_dir_nfs_options => "foo,bar"' do
      let(:params) {{ :manage_state_dir_nfs_mount => true, :state_dir_nfs_options => 'foo,bar' }}
      it { should contain_mount('StateSaveLocation').with_options('foo,bar') }
    end
  end

  context 'when manage_job_checkpoint_dir_nfs_mount => true' do
    let(:params) {{ :manage_job_checkpoint_dir_nfs_mount => true }}

    it do
      should contain_mount('JobCheckpointDir').with({
        :ensure   => 'mounted',
        :name     => '/var/lib/slurm/checkpoint',
        :atboot   => 'true',
        :device   => nil,
        :fstype   => 'nfs',
        :options  => 'rw,sync,noexec,nolock,auto',
        :require  => 'File[JobCheckpointDir]',
      })
    end

    context 'when job_checkpoint_dir_nfs_device => "192.168.1.1:/slurm/checkpoint"' do
      let(:params) {{ :manage_job_checkpoint_dir_nfs_mount => true, :job_checkpoint_dir_nfs_device => '192.168.1.1:/slurm/checkpoint' }}
      it { should contain_mount('JobCheckpointDir').with_device('192.168.1.1:/slurm/checkpoint') }
    end

    context 'when job_checkpoint_dir_nfs_options => "foo,bar"' do
      let(:params) {{ :manage_job_checkpoint_dir_nfs_mount => true, :job_checkpoint_dir_nfs_options => 'foo,bar' }}
      it { should contain_mount('JobCheckpointDir').with_options('foo,bar') }
    end
  end
end

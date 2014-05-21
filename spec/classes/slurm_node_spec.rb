require 'spec_helper'

describe 'slurm::node' do
  let(:facts) { default_facts }
  let(:params) {{ }}
  let(:pre_condition) { "class { 'slurm': }" }

  it { should create_class('slurm::node') }
  it { should contain_class('slurm') }

  it { should contain_anchor('slurm::node::start').that_comes_before('Class[slurm::user]') }
  it { should contain_class('slurm::user').that_comes_before('Class[slurm::munge]') }
  it { should contain_class('slurm::munge').that_comes_before('Class[slurm::install]') }
  it { should contain_class('slurm::config::common').that_comes_before('Class[slurm::config]') }
  it { should contain_anchor('slurm::node::end') }

  it do
    should contain_class('slurm::install').with({
      :ensure           => 'present',
      :package_require  => nil,
      :use_pam          => 'false',
      :with_devel       => 'false',
    }).that_comes_before('Class[slurm::config::common]')
  end

  it do
    should contain_class('slurm::config').with({
      :manage_slurm_conf  => 'true',
    }).that_comes_before('Class[slurm::node::config]')
  end

  it do
    should contain_class('slurm::node::config').with({
      :manage_scripts   => 'false',
      :manage_logrotate => 'true',
    }).that_comes_before('Class[slurm::service]')
  end

  it do
    should contain_class('slurm::service').with({
      :ensure => 'running',
      :enable => 'true',
    }).that_comes_before('Anchor[slurm::node::end]')
  end

  it do
    should contain_firewall('100 allow access to slurmd').with({
      :proto  => 'tcp',
      :dport  => '6818',
      :action => 'accept',
    })
  end

  context 'when manage_slurm_conf => false' do
    let(:params) {{ :manage_slurm_conf => false }}
    
    it { should contain_class('slurm::config').with_manage_slurm_conf('false') }
  end

  context 'when manage_firewall => false' do
    let(:params) {{ :manage_firewall => false }}
    it { should_not contain_firewall('100 allow access to slurmd') }
  end

  # Test validate_bool parameters
  [
    'manage_slurm_conf',
    'manage_scripts',
    'with_devel',
    'manage_firewall',
    'manage_logrotate',
  ].each do |param|
    context "with #{param} => 'foo'" do
      let(:params) {{ param => 'foo' }}
      it { expect { should create_class('slurm::node') }.to raise_error(Puppet::Error, /is not a boolean/) }
    end
  end
end
# Private class
class slurm::common::install {

  Package {
    ensure  => $slurm::version,
    require => $slurm::package_require,
  }

  package { 'slurm': }
  package { 'slurm-munge': }

  if $slurm::node or $slurm::controller or $slurm::client {
  #  if $release == '16.05' {
  #    package { 'slurm': }
  #    package { 'slurm-devel': }
  #    package { 'slurm-munge': }
  #    package { 'slurm-perlapi': }
  #    package { 'slurm-plugins': }
  #    package { 'slurm-sjobexit': }
  #    package { 'slurm-sjstat': }
  #  }
  #  if $release == '17.02' {
      # package { 'slurm':
      #  ensure => installed,
      #  audit  => true,
      #}~>
      # package { 'slurm-spank-x11':
      #  ensure               => installed,
      #  before               => File["SLURM SPANK x11 config"],
      #  reinstall_on_refresh => true,
      #}
      package { 'slurm-devel': }
      package { 'slurm-perlapi': }
      package { 'slurm-plugins': }
      package { 'slurm-contribs': }
    #}
  }

  if $slurm::slurmdbd {
    package { 'slurm-slurmdbd': }
    package { 'slurm-sql': }
  }

  if $slurm::install_pam            { package { 'slurm-pam_slurm': } }
  if $slurm::install_torque_wrapper { package { 'slurm-torque': } }
  if $slurm::install_lua            { package { 'slurm-lua': } }
  #if $slurm::install_blcr           { package { 'slurm-blcr': } }

}

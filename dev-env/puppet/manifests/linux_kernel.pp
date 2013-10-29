
# Linux kernel

class linux_kernel {
  require cross_comp::tree
  #include
  #  linux_kernel::download,
  #  linux_kernel::build
}

class linux_kernel::params {
  include cross_comp::params

  $version   = '3.8.5' # version min, not really the current version
  $git       = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git"
  $dirname   = "linux-stable"
  $defconfig = "mpc85xx_smp_defconfig"
  $dir       = "${cross_comp::params::tmp_dir}/${dirname}"
}

class linux_kernel::download {
  include linux_kernel::params,
    cross_comp::params

  file { "linux_kernel::create_git_dir":
    path   => $linux_kernel::params::dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  exec { "linux_kernel::clone_git":
    command => "/usr/bin/git clone ${linux_kernel::params::git} ${linux_kernel::params::dir} && \
                /usr/bin/touch ${linux_kernel::params::dir}/.puppet_cloned",
    cwd     => $linux_kernel::params::dir,
    creates => "${linux_kernel::params::dir}/.puppet_cloned",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => [ File["linux_kernel::create_git_dir"], Package["git"] ]
  }

}

class linux_kernel::headers {
  require linux_kernel::download,
  binutils::build,
  gcc::build
  include linux_kernel::params,
    cross_comp::params

  exec { "linux_kernel::make_headers_install":
    command => "make headers_install ARCH=${cross_comp::params::arch} \
                CROSS_COMPILE=${cross_comp::params::target}- \
                INSTALL_HDR_PATH=${cross_comp::params::sysroot}/usr \
                -j ${cross_comp::params::j} && \
                /usr/bin/touch ${linux_kernel::params::dir}/.puppet_headers_installed",
    cwd     => $linux_kernel::params::dir,
    path    => $cross_comp::params::path_env,
    creates => "${linux_kernel::params::dir}/.puppet_headers_installed",
    timeout => 0,
  }
}

class linux_kernel::build {
  require linux_kernel::download,
  binutils::build,
  gcc::build
  include linux_kernel::params,
    cross_comp::params

  exec { "linux_kernel::make_conf":
    command => "make ${linux_kernel::params::defconfig} ARCH=${cross_comp::params::arch} \
                -j ${cross_comp::params::j} && \
                /usr/bin/touch ${linux_kernel::params::dir}/.puppet_configured",
    cwd     => $linux_kernel::params::dir,
    path    => $cross_comp::params::path_env,
    creates => "${linux_kernel::params::dir}/.puppet_configured",
    timeout => 0,
    user    => $cross_comp::params::user,
  }

  exec { "linux_kernel::make_build":
    command => "make CROSS_COMPILE=${cross_comp::params::target}- ARCH=${cross_comp::params::arch} uImage \
                -j ${cross_comp::params::j} --sysroot=${cross_comp::params::sysroot} && \
                /usr/bin/touch ${linux_kernel::params::dir}/.puppet_compiled",
    cwd     => $linux_kernel::params::dir,
    path    => $cross_comp::params::path_env,
    creates => "${linux_kernel::params::dir}/.puppet_compiled",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => Exec["linux_kernel::make_conf"]
  }
}

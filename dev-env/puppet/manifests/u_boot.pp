
# U-Boot

class u_boot {
  require cross_comp::tree

  include u_boot::download,
    u_boot::build
}

class u_boot::params {
  include cross_comp::params
  
  $git       = "git://git.denx.de/u-boot.git" # "git://git.freescale.com/ppc/sdk/u-boot.git"
  $dirname   = "u-boot-git"
  $dir       = "${cross_comp::params::tmp_dir}/${dirname}"
  $config    = "P1022DS_36BIT_SDCARD"
}

class u_boot::download {
  include u_boot::params,
    cross_comp::params

  file { "u_boot::create_git_dir":
    path   => $u_boot::params::dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }
  
  exec { "u_boot::clone_git":
    command => "/usr/bin/git clone ${u_boot::params::git} ${u_boot::params::dir} && \
                /usr/bin/touch ${u_boot::params::dir}/.puppet_cloned",
    cwd     => $u_boot::params::dir,
    creates => "${u_boot::params::dir}/.puppet_cloned",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => [ File["u_boot::create_git_dir"], Package["git"] ]
  }
  
}

class u_boot::build {
  require u_boot::download,
  binutils::build,
  gcc::build
  include u_boot::params,
    cross_comp::params
  
  exec { "u_boot::make_conf":
    command     => "make -j ${cross_comp::params::j} \
                    ARCH=${cross_comp::params::arch} \
                    CROSS_COMPILE=${cross_comp::params::target}- \
                    CC=\"${cross_comp::params::target}-gcc --sysroot=${cross_comp::params::sysroot}\" \
                    O=${u_boot::params::config} ${u_boot::params::config}
                    && /usr/bin/touch ${u_boot::params::dir}/.puppet_configured",
    cwd         => $u_boot::params::dir,
    path        => $cross_comp::params::path_env,
    creates     => "${u_boot::params::dir}/.puppet_configured",
    timeout     => 0,
    user        => $cross_comp::params::user,
  }

  exec { "u_boot::make_build":
    command     => "make -j ${cross_comp::params::j} \
                    CROSS_COMPILE=${cross_comp::params::target}- \
                    ARCH=${cross_comp::params::arch} \
                    CC=\"${cross_comp::params::target}-gcc --sysroot=${cross_comp::params::sysroot}\" \
                    O=${u_boot::params::config} all \
                    && /usr/bin/touch ${u_boot::params::dir}/.puppet_compiled",
    cwd         => $u_boot::params::dir,
    path        => $cross_comp::params::path_env,
    creates     => "${u_boot::params::dir}/.puppet_compiled",
    timeout     => 0,
    user        => $cross_comp::params::user,
    require     => Exec["u_boot::make_conf"]
  }
}

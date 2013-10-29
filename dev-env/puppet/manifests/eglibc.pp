
# eglibc

class eglibc {
  require cross_comp::tree
  include eglibc::download,
    eglibc::headers,
    eglibc::build
}

class eglibc::params {
  include cross_comp::params,
    linux_kernel::params

  $version           = '2_17' # with underscore!
  $svn               = "http://www.eglibc.org/svn/branches/eglibc-${version}"
  $dirname           = "eglibc-${version}"
  $dir               = "${cross_comp::params::tmp_dir}/${dirname}"
  $headers_build_dir = "${cross_comp::params::tmp_dir}/headers_${dirname}"
  $build_dir         = "${cross_comp::params::tmp_dir}/build_${dirname}"
  $config_args       = "--disable-profile --without-gd --without-cvs \
                        --enable-add-ons --enable-kernel=${linux_kernel::params::version}"
}

class eglibc::download {
  include eglibc::params,
    cross_comp::params

  exec { "eglibc::create_svn":
    command => "/usr/bin/svn co ${eglibc::params::svn} ${eglibc::params::dir} &&\
                /usr/bin/touch ${eglibc::params::dir}/.puppet_checkout",
    cwd     => $cross_comp::params::tmp_dir,
    creates => "${eglibc::params::dir}/.puppet_checkout",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => Package["subversion"]
  }

}

class eglibc::headers {
  require eglibc::download,
  gcc::build,
  linux_kernel::headers
  include eglibc::params,
    cross_comp::params

  file { "eglibc::build_headers_dir":
    path   => $eglibc::params::headers_build_dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  exec { "eglibc::make_headers":
    command     => "${eglibc::params::dir}/libc/configure --prefix=/usr \
                    --with-headers=${cross_comp::params::sysroot}/usr/include \
                    --host=${cross_comp::params::target} \
                    ${eglibc::params::config_args} && \
                    touch ${eglibc::params::headers_build_dir}/.puppet_configured",
    cwd         => $eglibc::params::headers_build_dir,
    path        => $cross_comp::params::path_env,
    creates     => "${eglibc::params::headers_build_dir}/.puppet_configured",
    user        => $cross_comp::params::user,
    environment => [ "BUILD_CC=gcc",
                     "CC=${cross_comp::params::prefix}/bin/${cross_comp::params::target}-gcc",
                     "CXX=${cross_comp::params::prefix}/bin/${cross_comp::params::target}-g++",
                     "AR=${cross_comp::params::prefix}/bin/${cross_comp::params::target}-ar",
                     "RANLIB=${cross_comp::params::prefix}/bin/${cross_comp::params::target}-ranlib" ],
    timeout     => 0,
    require     => File["eglibc::build_headers_dir"]
  }

  exec { "eglibc::make_headers_install":
    command => "make install-headers install_root=${cross_comp::params::sysroot} \
                install-bootstrap-headers=yes &&\
                touch ${eglibc::params::headers_build_dir}/.puppet_installed",
    cwd     => $eglibc::params::headers_build_dir,
    path    => $cross_comp::params::path_env,
    creates => "${eglibc::params::headers_build_dir}/.puppet_installed",
    timeout => 0,
    require => Exec["eglibc::make_headers"]
  }

  exec { "eglibc::make_headers_hand":
    command  => "mkdir -p ${cross_comp::params::sysroot}/usr/lib && \
                 make csu/subdir_lib && \
                 cp ${eglibc::params::headers_build_dir}/csu/crt[1in].o ${cross_comp::params::sysroot}/usr/lib && \
                 ${cross_comp::params::prefix}/bin/${cross_comp::params::target}-gcc -nostdlib -nostartfiles \
                 -shared -x c /dev/null -o ${cross_comp::params::sysroot}/usr/lib/libc.so && \
                 touch ${eglibc::params::headers_build_dir}/.puppet_hand_steps",
    cwd     => $eglibc::params::headers_build_dir,
    path    => $cross_comp::params::path_env,
    creates => "${eglibc::params::headers_build_dir}/.puppet_hand_steps",
    timeout => 0,
    require => Exec["eglibc::make_headers_install"]

  }
}

class eglibc::build {
  require eglibc::headers,
  gcc::build2
  include eglibc::params,
    cross_comp::params

  file { "eglibc::build::build_dir":
    path   => $eglibc::params::build_dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  exec { "eglibc::build::make_config":
    command     => "${eglibc::params::dir}/libc/configure --prefix=/usr \
                    --with-headers=${cross_comp::params::sysroot}/usr/include \
                    --host=${cross_comp::params::target} \
                    ${eglibc::params::config_args} && \
                    touch ${eglibc::params::build_dir}/.puppet_configured",
    cwd         => $eglibc::params::build_dir,
    path        => $cross_comp::params::path_env,
    environment => $cross_comp::params::env_cross,
    creates     => "${eglibc::params::build_dir}/.puppet_configured",
    user        => $cross_comp::params::user,
    timeout     => 0,
    require     => [ File["eglibc::build::build_dir"], Package["gperf"] ]
  }

  exec { "eglibc::build::make":
    command     => "make -j ${cross_comp::params::j} && \
                    touch ${eglibc::params::build_dir}/.puppet_compiled",
    cwd         => $eglibc::params::build_dir,
    path        => $cross_comp::params::path_env,
    environment => $cross_comp::params::env_cross,
    creates     => "${eglibc::params::build_dir}/.puppet_compiled",
    user        => $cross_comp::params::user,
    timeout     => 0,
    require     => Exec["eglibc::build::make_config"]
  }

  exec { "eglibc::build::make_install":
    command     => "make install install_root=${cross_comp::params::sysroot} -j ${cross_comp::params::j} && \
                    touch ${eglibc::params::build_dir}/.puppet_installed",
    cwd         => $eglibc::params::build_dir,
    path        => $cross_comp::params::path_env,
    environment => $cross_comp::params::env_cross,
    creates     => "${eglibc::params::build_dir}/.puppet_installed",
    timeout     => 0,
    require     => Exec["eglibc::build::make"]
  }
}

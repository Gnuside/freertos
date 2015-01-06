# GCC

class gcc($config) {
  require cross_comp::tree
  include gcc::params($config),
    gcc::download,
    gcc::build,
    gcc::build3
}

class gcc::params($config) {
  include cross_comp::params

  $version        = '4.7.2'
  $filename       = "gcc-${version}"
  $ftp_host       = "ftp://ftp.gnu.org"
  # Mirrors: ftp://gcc.gnu.org/pub/gcc/releases/ (but with md5 verification)
  $ftp_dir        = "gnu/gcc/${filename}"
  $dir            = "${cross_comp::params::tmp_dir}/${filename}"
  $build_dir      = "${cross_comp::params::tmp_dir}/build_${filename}"
  $build_dir2     = "${build_dir}_2"
  $build_dir3     = "${build_dir}_3"
  $arch_flags     = "--enable-e500_double \
                     --with-long-double-128 \
                     --with-cpu=8548"
  $configure_args = "--with-sysroot=${cross_comp::params::sysroot} \
                     ${arch_flags} \
                     --disable-libmudflap \
                     --disable-multilib"
  $target_flags   = "-m32 -mcpu=8548 -mabi=spe -mspe -mfloat-gprs=double"
  $languages      = "c,c++"
}

class gcc::download {
  include gcc::params,
    cross_comp::params

  #exec { "${name}-extracted-files-integrity":
   # command => "/usr/bin/md5sum --strict --status --quiet -c MD5SUMS",
    #cwd => $cross_comp::params::dir,
    #timeout => 0
  #}

  cross_comp::download_gnu { "gcc::download_gnu":
    host       => $gcc::params::ftp_host,
    server_dir => $gcc::params::ftp_dir,
    creates_f  => $gcc::params::filename,
    dst_dir    => $cross_comp::params::tmp_dir
  }

}

class gcc::build {
  require gcc::download,
  binutils::build
  include gcc::params

  file { "gcc::build_dir":
    path   => $gcc::params::build_dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  # download prerequisites (libgmp, libmpc and libmpfr)

  exec { "gcc::build-prerequisites":
    command => "${gcc::params::dir}/contrib/download_prerequisites",
    cwd     => $gcc::params::dir,
    creates => "${gcc::params::dir}/gmp", # and mpc and mpfr
  }

  cross_comp::build_gnu { "gcc::build_gnu":
    build_dir      => $gcc::params::build_dir,
    source_dir     => $gcc::params::dir,
    configure_args => "--without-headers \
                       --with-newlib \
                       --disable-shared \
                       --disable-threads \
                       --enable-languages=c \
                       --disable-decimal-float \
                       --disable-__cxa_atexit \
                       --disable-libquadmath \
                       --disable-libssp \
                       --disable-libgomp \
                       --disable-nls \
                       ${gcc::params::configure_args}",
    environment    => ["AR=ar"],
    make_rule      => "ARCH_FLAGS_FOR_TARGET='${gcc::params::target_flags}' \
                       all-host all-target-libgcc",
    install_rule   => "install-host install-target-libgcc",
    require        => [ Exec["gcc::build-prerequisites"],
                        File["gcc::build_dir"] ]
  }
}

class gcc::build2 {
  include gcc::params

  file { "gcc::build_dir2":
    path   => $gcc::params::build_dir2,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  cross_comp::build_gnu { "gcc::build_gnu2":
    build_dir      => $gcc::params::build_dir2,
    source_dir     => $gcc::params::dir,
    configure_args => "--enable-languages=c \
                       --disable-decimal-float \
                       --disable-libquadmath \
                       --disable-libssp \
                       --disable-libgomp \
                       --disable-nls \
                       --enable-shared \
                       ${gcc::params::configure_args}",
    environment    => ["AR=ar"],
    make_rule      => "ARCH_FLAGS_FOR_TARGET='${gcc::params::target_flags}' \
                       all-host all-target-libgcc",
    install_rule   => "install-host install-target-libgcc",
    require        => [ Class["eglibc::headers"], File["gcc::build_dir2"] ]
  }
}

class gcc::build3 {
  include gcc::params

  file { "gcc::build_dir3":
    path   => $gcc::params::build_dir3,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  cross_comp::build_gnu { "gcc::build_gnu3":
    build_dir      => $gcc::params::build_dir3,
    source_dir     => $gcc::params::dir,
    configure_args => "--enable-languages=${gcc::params::languages} \
                       --enable-__cxa_atexit \
                       --enable-c99 \
                       --enable-shared \
                       ${gcc::params::configure_args}",
    environment    => ["AR=ar"],
    make_rule      => "ARCH_FLAGS_FOR_TARGET='${gcc::params::target_flags}' \
                       all-host all-target-libgcc",
    install_rule   => "install-host install-target-libgcc",
    require        => [ Class["eglibc::build"], File["gcc::build_dir3"] ]
  }
}


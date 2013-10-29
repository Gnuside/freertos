
class binutils {
  require cross_comp::tree
  include binutils::params,
    binutils::download,
    binutils::build
}

class binutils::params {
  include cross_comp::params

  $version     = '2.23.2'
  $filename    = "binutils-${version}"
  $ftp_host    = "ftp://ftp.gnu.org"
  $ftp_dir     = "gnu/binutils"
  $dir         = "${cross_comp::params::tmp_dir}/${filename}"
  $build_dir   = "${cross_comp::params::tmp_dir}/build_${filename}"
}

class binutils::download {
  include binutils::params,
    cross_comp::params

  cross_comp::download_gnu { "binutils::download_gnu":
    host       => $binutils::params::ftp_host,
    server_dir => $binutils::params::ftp_dir,
    creates_f  => $binutils::params::filename,
    dst_dir    => $cross_comp::params::tmp_dir
  }

}

class binutils::build {
  require binutils::download
  include binutils::params,
    cross_comp::params

  file { "binutils::build_dir":
    path   => $binutils::params::build_dir,
    ensure => "directory",
    owner  => $cross_comp::params::user
  }

  cross_comp::build_gnu { "binutils::build_gnu":
    configure_args => "--with-sysroot=${cross_comp::params::sysroot} \
                       --disable-nls --disable-multilib",
    environment    => ["AR=ar", "AS=as"],
    build_dir      => $binutils::params::build_dir,
    source_dir     => $binutils::params::dir,
  }
}

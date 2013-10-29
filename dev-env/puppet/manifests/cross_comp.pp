
class cross_comp {
  # include cross_comp::params
  require cross_comp::tree

  /*exec { "cross_comp-remove-temp-dir":
    command => "/bin/rm -r ${cross_comp::params::tmp_dir}",
    require => [ Class["binutils::build"], Class["gcc::build"],
                 Class["linux_kernel::build"], Class["eglibc::build"] ]
  }*/
}

class cross_comp::params {

  if $domain != 'localdomain' {
    $target_id   = 'vagrant'
    $target_path = '/home/vagrant'
  } elsif $target_id == '' {
    alert("Please specify the target username with FACTER_target_id")
    require "target_id" # Exits Puppet
  } elsif $target_path == '' {
    alert("Please specify the target home path with FACTER_target_path")
    require "target_path" # Exits Puppet
  }

  if $processorcount > 1 {
    $j = ($processorcount * 3) / 2 # threads = core_count * 1.5
  } else {
    $j = 1
  }

  $arch       = "powerpc"
  # $build    = "$(echo $MACHTYPE | sed -e 's/-[^-]*/-cross/')"
  $target     = "${arch}-e500v2-linux-gnuspe"
  $user       = "${target_id}"
  $prefix     = "${target_path}/tools"
  $sysroot    = "${target_path}/sysroot"
  $tmp_dir    = "${target_path}/tmp" # '/tmp/puppet_cross_comp'
  $path_env   = "${prefix}/bin:/bin:/usr/bin"
  $bin_prefix = "${prefix}/bin/${target}-"
  $env_cross  = [ "BUILD_CC=gcc",
                  "CC=${bin_prefix}gcc",
                  "BUILD_CXX=g++",
                  "CXX=${bin_prefix}g++",
                  "BUILD_AR=ar",
                  "AR=${bin_prefix}ar",
                  "BUILD_AS=as",
                  "AS=${bin_prefix}as",
                  "BUILD_LD=ld",
                  "LD=${bin_prefix}ld",
                  "BUILD_NM=nm",
                  "NM=${bin_prefix}nm",
                  "BUILD_RANLIB=ranlib",
                  "RANLIB=${bin_prefix}ranlib",
                  "BUILD_STRIP=strip",
                  "STRIP=${bin_prefix}strip",
                  "OBJCOPY=${bin_prefix}objcopy",
                  "OBJDUMP=${bin_prefix}objdump" ]
}

class cross_comp::tree {
  include cross_comp::params

  user { "${cross_comp::params::user}":
    gid        => $cross_comp::params::user,
    ensure     => "present",
    managehome => true
  }

  file { "cross_comp-create-temp-dir":
    path    => $cross_comp::params::tmp_dir,
    ensure  => "directory",
    owner   => $cross_comp::params::user,
    require => User[$cross_comp::params::user]
  }

  file { "cross_comp-create_sysroot":
    path    => $cross_comp::params::sysroot,
    ensure  => "directory",
    owner   => $cross_comp::params::user,
    require => User[$cross_comp::params::user]
  }

  file { "cross_comp-create_tools":
    path    => $cross_comp::params::prefix,
    ensure  => "directory",
    owner   => $cross_comp::params::user,
    require => User[$cross_comp::params::user]
  }
}

class cross_comp::download {
  package {
    "wget":       ensure => installed ;
    "tar":        ensure => installed ;
    "bzip2":      ensure => installed ;
    "gzip":       ensure => installed ;
    "git":        ensure => installed ;
    "subversion": ensure => installed ;
  }
}

class cross_comp::build {
  package {
    "build-essential": ensure => installed ;
    "sed":             ensure => installed ;
    "automake":        ensure => installed ;
    "autoconf":        ensure => installed ;
    "coreutils":       ensure => installed ;
    "diffutils":       ensure => installed ;
    "gawk":            ensure => installed ;
    "gcc":             ensure => installed ;
    "texinfo":         ensure => installed ;
    "g++":             ensure => installed ;
    "uboot-mkimage":   ensure => installed ;
    "gperf":           ensure => installed ;
  }
}

define cross_comp::download_gnu ($host, $server_dir, $creates_f, $dst_dir) {
  include cross_comp::download

  $archive = "${creates_f}.tar.bz2"

  $keyring = "${dst_dir}/gnu-keyring.gpg"

  exec { "${name}-get-keyring":
    command => "/usr/bin/wget ${host}/gnu/gnu-keyring.gpg",
    cwd     => $dst_dir,
    creates => $keyring,
    onlyif  => "/usr/bin/test ! -f ${keyring}",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => Package["wget"]
  }

  $sig = "${dst_dir}/${archive}.sig"

  exec { "${name}-get-sig":
    command => "/usr/bin/wget ${host}/${server_dir}/${archive}.sig",
    cwd     => $dst_dir,
    creates => $sig,
    onlyif  => "/usr/bin/test ! -f ${sig}",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => Package["wget"]
  }

  $createsf = "${dst_dir}/${archive}"

  exec { "${name}-get":
    command => "/usr/bin/wget ${host}/${server_dir}/${archive}",
    cwd     => $dst_dir,
    creates => $createsf,
    onlyif  => "/usr/bin/test ! `/usr/bin/gpg --verify --keyring ${keyring} ${sig}`",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => [ Package["wget"],
                 Exec["${name}-get-keyring"],
                 Exec["${name}-get-sig"] ]
  }

  # TODO: if gpg returns false... remove keyring, sig and archive and retry once

  exec { "${name}-unpack":
    command => "/bin/tar -jxvf ${archive}",
    cwd     => $dst_dir,
    creates => "${dst_dir}/${creates_f}",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => [ Exec["${name}-get"], Package["tar"],
                 Package["bzip2"] ]
  }
}

define cross_comp::build_gnu ($source_dir, $build_dir, $configure_args = "",
                              $make_rule = "all", $install_rule = "install",
                              $environment = []) {
  include cross_comp::params
  require cross_comp::build

  exec { "${name}-configure":
    command     => "${source_dir}/configure --target=${cross_comp::params::target} \
                    --prefix=${cross_comp::params::prefix} ${configure_args} && \
                    /usr/bin/touch ${build_dir}/.puppet_configured",
    cwd         => $build_dir,
    path        => $cross_comp::params::path_env,
    onlyif      => "/usr/bin/test -d ${source_dir} && \
                    /usr/bin/test -d ${build_dir}",
    creates     => "${build_dir}/.puppet_configured",
    environment => $environment,
    timeout     => 0,
    user        => $cross_comp::params::user,
    require     => Package["sed"],
    before      => Exec["${name}-make-all"]
  }

  exec { "${name}-make-all":
    command => "make ${make_rule} -j ${cross_comp::params::j} && \
                /usr/bin/touch ${build_dir}/.puppet_compiled",
    cwd     => $build_dir,
    path    => $cross_comp::params::path_env,
    creates => "${build_dir}/.puppet_compiled",
    timeout => 0,
    user    => $cross_comp::params::user,
    require => Exec["${name}-configure"]
  }

  exec { "${name}-make-install":
    command => "make ${install_rule} -j ${cross_comp::params::j} && \
                /usr/bin/touch ${build_dir}/.puppet_installed",
    cwd     => $build_dir,
    path    => $cross_comp::params::path_env,
    creates => "${build_dir}/.puppet_installed",
    timeout => 0,
    require => Exec["${name}-make-all"]
  }
}

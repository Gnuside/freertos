# Class: crosscomp
#
# Compiles binutils, GCC and the linux kernel
# for a chosen architecture (currently powerpc).
#
# Parameters: none
#
# Actions:
#
#   Declares all other classes in the crosscomp module.
#
# Requires: nothing
#

node "vagrant-debian-wheezy.vagrantup.com" {

  $config_gcc         = loadyaml('/vagrant/config/gcc.yml')
  $config_binutils    = loadyaml('/vagrant/config/binutils.yml')
  $config_crosscomp   = loadyaml('/vagrant/config/crosscomp.yml')
  $config_eglibc      = loadyaml('/vagrant/config/eglibc.yml')

  class {
    "cross_comp":
      config => $config_crosscomp;
    "binutils":
      config => $config_binutils;
    "gcc":
      config => $config_gcc;
    "eglibc":
      config => $config_eglibc
  }

  if $osfamily == "Debian" {
    class{ "apt":  always_apt_update => true; }

    apt::key {
      "B98321F9":
        key_source => "http://ftp-master.debian.org/keys/archive-key-6.0.asc";
      "473041FA":
        key_source => "http://ftp-master.debian.org/keys/archive-key-6.0.asc";
      "F42584E6":
        key_source => "http://ftp-master.debian.org/keys/archive-key-6.0.asc"
    }

    Apt::Key <| |> -> Exec["apt_update"]
    Exec["apt_update"] -> Package <| |>
  }
}

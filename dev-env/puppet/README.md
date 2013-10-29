Puppet cross compilation
========================

Classes description
-------------------

* "cross_comp" creates some needed directories.
* "binutils" downloads and compiles binutils for another arch (defined in cross_comp).
* "gcc" downloads and compiles GCC for another arch (defined in cross_comp). It takes three steps to compile:
  - gcc::build (minimal): after binutils
  - gcc::build2 (with shared and threads): after eglibc::headers
  - gcc::build3 (complete): at the end
* "linux_kernel" downloads, installs headers and optionnaly compiles the Linux kernel.
* "eglibc" downloads, installs headers and compiles libc for another arch (defined in cross_comp).
* "u_boot" optionnaly downloads, and compiles the Das U-Boot bootloader.

Cached executions
-----------------

* Some executions does not need to be executed again, so invisible files are created:
 - .puppet_configured after a configure command
 - .puppet_builded after a make command
 - .puppet_installed after a make install command
* And some specific files:
 - .puppet_cloned (for a git command) -> kernel git
 - .puppet_headers_installed (for linux headers installation)
 - .puppet_checkout (for a svn command) -> eglibc svn

Tree
----

Except for the linux kernel and Das U-Boot, each build is done in a
separate directory prefixed by "build_".<br />
Here is the organization of directories:

* sysroot
* tmp
  - binutils-_{binutils\_version}_
  - build\_binutils-_{binutils\_version}_
  - build\_eglibc-_{eglibc\_version}_
  - build\_gcc-_{gcc\_version}_
  - build\_gcc-_{gcc\_version}_\_2
  - build\_gcc-_{gcc\_version}_\_3
  - build\_linux-stable
  - build\_u-boot-git
  - eglibc-_{eglibc\_version}_
  - gcc-_{gcc\_version}_
  - headers\_eglibc-_{eglibc\_version}_
  - linux-stable
  - u-boot-git
* tools -> cross compiled tools (programs and libs)



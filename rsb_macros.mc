#
# Extra options for RTEMS Source Builder
#

#
# GCC options. For defaults, refer to the file "gcc-common-1.cfg" in the RSB directory.
# Documentation:
#   https://gcc.gnu.org/onlinedocs/libstdc++/manual/configure.html
#   https://gcc.gnu.org/install/configure.html
#
gcc_configure_extra_options: none, override, '''\
--enable-libstdcxx-threads=yes \
--enable-libstdcxx-time=yes \
--enable-tls \
--enable-threads=rtems \
--enable-lto \
'''

#!/bin/bash
#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

ELF=$1
PORT=${2:-'/dev/ttyACM0'}

if [ -z "$ELF" ]; then
    >&2 echo "Usage:"
    >&2 echo "    `basename $0` <elf-path> [blackmagic-port]"
    >&2 echo "Default port is $PORT"
    >&2 echo "Example:"
    >&2 echo "    `basename $0` hello.exe"
    exit 1
fi

arm-rtems4.11-size $ELF || exit 1

tmpfile=blackmagic-gdb-cmds.temp
cat > $tmpfile <<EOF
target extended-remote $PORT
mon swdp_scan
attach 1
load
kill
EOF

arm-rtems4.11-gdb $ELF --batch -x $tmpfile
rm $tmpfile

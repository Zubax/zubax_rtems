#!/bin/bash
#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

ELF=$1

if [ -n "$2" ]; then
    BLACKMAGIC_PORT=$2
fi
if [ -z "$BLACKMAGIC_PORT" ]; then
    BLACKMAGIC_PORT=/dev/ttyACM0
    echo "Using default port $BLACKMAGIC_PORT; set the environment variable BLACKMAGIC_PORT to override"
fi

if [ -z "$ELF" ]; then
    >&2 echo "Usage:"
    >&2 echo "    `basename $0` <elf-path> [blackmagic-port]"
    >&2 echo "Default port is $BLACKMAGIC_PORT"
    >&2 echo "Default port can be set via environment variable BLACKMAGIC_PORT"
    >&2 echo "Example:"
    >&2 echo "    `basename $0` hello.ralf"
    exit 1
fi

arm-rtems4.11-size $ELF || exit 1

tmpfile=blackmagic-gdb-cmds.temp
cat > $tmpfile <<EOF
target extended-remote $BLACKMAGIC_PORT
mon swdp_scan
attach 1
load
kill
EOF

arm-rtems4.11-gdb $ELF --batch -x $tmpfile
rm $tmpfile

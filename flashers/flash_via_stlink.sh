#!/bin/bash
#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#

ELF=$1

if [ -z "$ELF" ]; then
    >&2 echo "Usage:"
    >&2 echo "    `basename $0` <elf-path>"
    >&2 echo "Example:"
    >&2 echo "    `basename $0` hello.exe"
    exit 1
fi

arm-rtems4.11-size $ELF || exit 1

binfile="`basename $ELF`.bin.temp"

arm-rtems4.11-objcopy -O binary $ELF $binfile

st-flash write $binfile 0x08000000

rm $binfile

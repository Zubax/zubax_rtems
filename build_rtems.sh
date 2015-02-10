#!/bin/bash
#
# Copyright (C) 2015 Pavel Kirienko <pavel.kirienko@zubax.com>
# Distributed under the terms of the MIT license.
#
# RTEMS building script.
#
# Resources:
#     http://ftp.rtems.org/pub/rtems/people/chrisj/source-builder/source-builder.html
#     http://alanstechnotes.blogspot.ru/2013/03/setting-up-rtems-development.html
#     http://s937484.blogspot.ru/2013/10/rtems-stm32f407-discovery-board-posted.html
#

STARTED_AT=$(date +%s)

TOPDIR=$(readlink -f $(dirname $0))

function fatal()
{
    tput setaf 1
    tput bold
    echo "FATAL ERROR: $@"
    tput sgr0
    exit 1
}

function echogreen()
{
    tput setaf 2
    tput bold
    echo "$@"
    tput sgr0
}

function echoblue()
{
    tput setaf 4
    tput bold
    echo "$@"
    tput sgr0
}

function usage()
{
    echo "Invalid usage. Supported options:"
    cat $0 | sed -n 's/^\s*--\([^)\*]*\).*)/\1/p' # Don't try this at home.
    exit 1
}

#
# Parsing the arguments. Read this section for usage info.
#
CPU=
BSP=
OVERWRITE_BSP_DIR=
AMEND_BSP_DIR=
BUILD_TOOLCHAIN=0
REMOVE_UNUSED_BSP=0

for i in "$@"; do
    case $i in
        --cpu=*)
            CPU="${i#*=}"
            ;;
        --bsp=*)
            BSP="${i#*=}"
            ;;
        --overwrite-bsp-dir=*)
            OVERWRITE_BSP_DIR="${i#*=}"
            ;;
        --amend-bsp-dir=*)
            AMEND_BSP_DIR="${i#*=}"
            ;;
        --build-toolchain)
            BUILD_TOOLCHAIN=1
            ;;
        --remove-unused-bsp)
            REMOVE_UNUSED_BSP=1
            ;;
        *)
            usage
            ;;
    esac
    shift
done

echoblue "CPU:               $CPU"
echoblue "BSP:               $BSP"
echoblue "OVERWRITE_BSP_DIR: $OVERWRITE_BSP_DIR"
echoblue "AMEND_BSP_DIR:     $AMEND_BSP_DIR"
echoblue "REMOVE_UNUSED_BSP: $REMOVE_UNUSED_BSP"

[ -z "$CPU" ] && usage
[ -z "$BSP" ] && usage

#
# Entire process assumes that the script directory is the current directory.
#
echo "Working directory: $TOPDIR"
cd $TOPDIR || fatal "Can't cd to working directory"

#
# Initializing the submodules
#
git submodule update --init --recursive || fatal "Can't update submodules"

if [ -z "$PARALLEL" ]; then
    export PARALLEL=$(grep -c ^processor /proc/cpuinfo)
    if [ -z "$PARALLEL" ]; then
        echo "Couldn't detect the number of processors, are we not on Linux?"
        export PARALLEL=4
    fi
    echo "Parallel jobs: $PARALLEL"
fi

#
# Building the toolchain if necessary
#
TOOLCHAIN_DIR=$TOPDIR/toolchain

function does_toolchain_exist()
{
    ls $TOOLCHAIN_DIR/bin/*gcc > /dev/null
}

if [[ $BUILD_TOOLCHAIN == 0 ]]; then
    if ! does_toolchain_exist; then
        echoblue "Toolchain not found, forcing rebuild"
        BUILD_TOOLCHAIN=1
    fi
fi

if [[ $BUILD_TOOLCHAIN != 0 ]]; then
    # Protection against accidental rebuild
    does_toolchain_exist && fatal "Toolchain appears to be built already. To rebuild, remove $TOOLCHAIN_DIR"

    echoblue "Building the toolchain..."
    rm -rf $TOOLCHAIN_DIR &> /dev/null

    #
    # Checking the environment
    #
    SB_LOG_FILE=$TOPDIR/rtems-source-builder.log
    function run_sb_check()
    {
        result=$($TOPDIR/rtems-source-builder/source-builder/sb-check --log=$SB_LOG_FILE 2>&1)
        status=$?
        echo "$result"
        [[ $status != 0 || $result =~ "error" || $result =~ "Environment is not correctly set up" ]] && return 1
        return 0
    }

    if ! run_sb_check; then
        echo "RTEMS SB check failed"
        read -p "Do you want me to install dependencies and retry? [y/N] " answer
        if [[ $answer =~ (y|Y) ]]; then
            if python -mplatform | grep -q Ubuntu; then
                sudo apt-get build-dep binutils gcc g++ gdb unzip git python2.7-dev
            else
                fatal "Can't help with your distribution, sorry"
            fi
        else
            fatal "Please fix it manually then"
        fi

        if ! run_sb_check; then
            fatal "Sorry, I couldn't fix it."
        fi
    fi

    echogreen "RTEMS SB check OK"

    #
    # Building the toolchain
    #
    cd $TOPDIR/rtems-source-builder/rtems
    echo "Available build sets:"
    ../source-builder/sb-set-builder --log=$SB_LOG_FILE \
                                     --list-bsets       \
        || fatal "Can't list build sets"

    ../source-builder/sb-set-builder --log=$SB_LOG_FILE      \
                                     --prefix=$TOOLCHAIN_DIR \
                                     4.11/rtems-$CPU         \
        || fatal "RSB build failed"

    echogreen "RTEMS SB succeeded"
fi

does_toolchain_exist || fatal "Toolchain not found"

#
# Environment configuration file
#
echoblue "Generating the environment configuration file..."
cd $TOPDIR
ENV_FILE=env.sh
cat << EOF > $ENV_FILE
#
# This file must be sourced in order for the build system to work.
#

export RTEMS_BSP=$BSP

# Toolchain path
export PATH=$TOOLCHAIN_DIR/bin:\$PATH

# Needed for applications
export RTEMS_MAKEFILE_PATH=$TOPDIR/bsps/$CPU-rtems4.11/\$RTEMS_BSP

# Convenience defines (not required)
export RTEMS_TOOLCHAIN_BASE=$TOOLCHAIN_DIR
export RTEMS_BSP_BASE=$TOPDIR/bsps
EOF

source $ENV_FILE || fatal "Can't source env file"

$CPU-rtems4.11-gcc -v || fatal "Toolchain test failed"

echogreen "Environment configuration file '$ENV_FILE' has been generated and sourced"

#
# Helper scripts
#
#cat << EOF > waf_configure.sh
#waf configure --rtems=$TOPDIR/bsps --rtems-tools=$TOOLCHAIN_DIR --rtems-bsps=$CPU/$BSP
#EOF
#chmod +x waf_configure.sh

#
# Copying the external BSP if specified, checking its validness
#
if [ -n "$OVERWRITE_BSP_DIR" ]; then
    bsp=$(basename $OVERWRITE_BSP_DIR)
    echoblue "Overwriting BSP $bsp"
    OVERWRITE_BSP_DIR_DST=$TOPDIR/rtems/c/src/lib/libbsp/$CPU/$bsp
    rm -rf $OVERWRITE_BSP_DIR_DST
    cp -vr $OVERWRITE_BSP_DIR $OVERWRITE_BSP_DIR_DST || fatal "Can't overwrite BSP"
fi

if [ -n "$AMEND_BSP_DIR" ]; then
    echoblue "Amending BSP"
    \cp -vrf $AMEND_BSP_DIR $TOPDIR/rtems/c/src/lib/libbsp/$CPU || fatal "Can't amend BSP"
fi

BSP_CUSTOM_FILE=($TOPDIR/rtems/c/src/lib/libbsp/$CPU/*/make/custom/$BSP.cfg)

[[ ${#BSP_CUSTOM_FILE[@]} > 1 ]] && \
    fatal "Conflicting BSP customization files found: ${BSP_CUSTOM_FILE[@]}"

[ -f "$BSP_CUSTOM_FILE" ] || fatal "BSP customization file not found"

BSP_DIR=$(readlink -f $(dirname $BSP_CUSTOM_FILE)/../..)

echo "BSP custom file: $BSP_CUSTOM_FILE"
echo "BSP directory:   $BSP_DIR"
echogreen "BSP check OK"

#
# Purging BSP we don't need - the radical way of making build go faster
#
if [[ $REMOVE_UNUSED_BSP != 0 ]]; then
    echoblue "Removing unused BSP..."
    #
    # CPU cleanup
    #
    for path in $TOPDIR/rtems/c/src/lib/libbsp/* \
                $TOPDIR/rtems/c/src/lib/libcpu/*
    do
        [ -d "${path}" ] || continue   # Not a directory
        cpu="$(basename ${path})"
        [[ "$cpu" == "$CPU" \
        || "$cpu" == "shared" \
        || "$cpu" == *.* \
        ]] && continue
        echo "Removing CPU $cpu"
        rm -rf ${path}
    done
    #
    # BSP cleanup
    #
    for path in $TOPDIR/rtems/c/src/lib/libbsp/$CPU/*; do
        [ -d "${path}" ] || continue
        bsp_dir="$(basename ${path})"
        [[ "$bsp_dir" == "$(basename $BSP_DIR)" \
        || "$bsp_dir" == "shared" \
        || "$bsp_dir" == *.* \
        ]] && continue
        echo "Removing BSP $bsp_dir"
        rm -rf ${path}
    done
fi

#
# Printing BSP configuration options
#
echo "Configuration options for BSP $BSP:"
cat $BSP_DIR/configure.ac | grep RTEMS_BSPOPTS_SET

#
# Building RTEMS
#
echoblue "Bootstrapping..."
cd $TOPDIR/rtems || fatal "Can't cd to rtems"
./bootstrap || fatal "Failed to bootstrap"

echoblue "Configuring..."
cd $TOPDIR
rm -rf rtems-build &> /dev/null
rm -rf $TOPDIR/bsps &> /dev/null
mkdir rtems-build
cd rtems-build || fatal "Can't cd to rtems-build"

../rtems/configure --target=$CPU-rtems4.11      \
                   --enable-tests=samples       \
                   --enable-rtemsbsp=$BSP       \
                   --enable-posix               \
                   --enable-languages=c,c++     \
                   --prefix=$TOPDIR/bsps

build_status=$?
if [[ $build_status != 0 ]]; then
    fatal "Configure failed with status $build_status"
fi

echoblue "Running make install in 'rtems-build' using $PARALLEL parallel jobs..."
make -j$PARALLEL install &> $TOPDIR/rtems-make.log || fatal "Make failed, see the log for details"

echogreen "RTEMS built successfully"

#
# Final report
#
echogreen "Finished successfully in $(( ($(date +%s) - $STARTED_AT) / 60 + 1 )) minutes"

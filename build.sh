#!/bin/bash

set -e

cd $(dirname ${0})

# ---------------------------------------------------------------------------------------------------------------------

target="${1}"

if [ -z "${target}" ]; then
    echo "usage: ${0} <target>"
    exit 1
fi

# ---------------------------------------------------------------------------------------------------------------------
# import PawPaw environment

export PAWPAW_SKIP_LTO=1

pushd PawPaw
source local.env ${target}
popd

# ---------------------------------------------------------------------------------------------------------------------
# build and package carla

if [ "${MACOS}" -eq 1 ] && [ "${MACOS_UNIVERSAL}" -eq 0 ]; then
    EXTRA_ARGS="HAVE_HYLIA=0 HAVE_QT5PKG=true"
    export MOC_QT5=moc
    export RCC_QT5=rcc
fi

pushd Carla
make features
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS} ${EXTRA_ARGS}
if [ "${MACOS}" -eq 1 ] && [ "${MACOS_UNIVERSAL}" -eq 0 ]; then
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS} ${EXTRA_ARGS} posix32
elif [ "${WIN64}" -eq 1 ]; then
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS} ${EXTRA_ARGS} win32r
fi
make dist ${MAKE_ARGS} ${EXTRA_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} ${EXTRA_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} ${EXTRA_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} ${EXTRA_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} ${EXTRA_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} ${EXTRA_ARGS} -j 1
popd

# ---------------------------------------------------------------------------------------------------------------------

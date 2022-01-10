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

pushd PawPaw
source local.env ${target}
popd

# ---------------------------------------------------------------------------------------------------------------------
# build and package carla

pushd Carla
make features
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS}
if [ "${MACOS}" -eq 1 ] && [ "${MACOS_UNIVERSAL}" -eq 0 ]; then
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS} posix32
elif [ "${WIN64}" -eq 1 ]; then
make EXTERNAL_PLUGINS=false NOOPT=true ${MAKE_ARGS} win32r
fi
make dist ${MAKE_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} TESTING=true -j 1
make dist ${MAKE_ARGS} -j 1
popd

# ---------------------------------------------------------------------------------------------------------------------

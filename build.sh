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
# non-travis builds

if [ -z "${BOOTSTRAP_VERSION}" ]; then
    BOOTSTRAP_VERSION=1
fi
if [ -z "${TRAVIS_BUILD_DIR}" ]; then
    TRAVIS_BUILD_DIR="$(pwd)"
fi

# ---------------------------------------------------------------------------------------------------------------------
# check build step

PAWPAW_DIR="${HOME}/PawPawBuilds"
PAWPAW_BUILDDIR="${PAWPAW_DIR}/builds/${target}"

if [ -e ${PAWPAW_BUILDDIR}/.last-bootstrap-version ]; then
    LAST_BOOTSTRAP_VERSION=$(cat ${PAWPAW_BUILDDIR}/.last-bootstrap-version)
else
    LAST_BOOTSTRAP_VERSION=0
fi

if [ ${LAST_BOOTSTRAP_VERSION} -eq ${BOOTSTRAP_VERSION} ] && [ -e ${PAWPAW_BUILDDIR}/.last-build-version ]; then
    LAST_BUILD_VERSION=$(cat ${PAWPAW_BUILDDIR}/.last-build-version)
else
    LAST_BUILD_VERSION=0
fi

BUILD_VERSION=$((${LAST_BUILD_VERSION} + 1))

mkdir -p ${PAWPAW_BUILDDIR}
echo ${BOOTSTRAP_VERSION} > ${PAWPAW_BUILDDIR}/.last-bootstrap-version

if [ ${BUILD_VERSION} -le 4 ]; then
    echo ${BUILD_VERSION} > ${PAWPAW_BUILDDIR}/.last-build-version
fi

echo "Carla-Releases build v${BUILD_VERSION}"

# ---------------------------------------------------------------------------------------------------------------------
# build dependencies according to version/step, caching files along the way

if [ ${BUILD_VERSION} -eq 1 ]; then
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-plugins.sh ${target}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${target}
    exit 0
fi

if [ ${BUILD_VERSION} -eq 2 ]; then
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-qt.sh ${target}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${target}
    exit 0
fi

if [ ${BUILD_VERSION} -eq 3 ]; then
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-carla.sh ${target}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${target}
    exit 0
fi

${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-carla.sh ${target}
${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${target}

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
make dist ${MAKE_ARGS} -j 1
popd

# ---------------------------------------------------------------------------------------------------------------------

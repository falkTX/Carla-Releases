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
# check build step

PAWPAW_DIR="${HOME}/PawPawBuilds"
PAWPAW_BUILDDIR="${PAWPAW_DIR}/builds/${TARGET}"

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
echo ${BUILD_VERSION} > ${PAWPAW_BUILDDIR}/.last-build-version

echo "Carla-Releases build v${BUILD_VERSION}"

# ---------------------------------------------------------------------------------------------------------------------
# build dependencies according to version/step, caching files along the way

if [ ${BUILD_VERSION} -eq 1 ]; then
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-plugins.sh ${TARGET}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${TARGET}
    exit 0
fi

if [ ${BUILD_VERSION} -eq 2 ]; then
    # qt build takes too long on macos-universal target, download and use premade builds
    if [ "${TARGET}" = "macos-universal" ]; then
        CROSS_COMPILING=1
        MACOS=1
        MACOS_OLD=0
        MACOS_UNIVERSAL=1
        WIN32=0
        source "${TRAVIS_BUILD_DIR}/PawPaw/setup/versions.sh"
        mkdir "${PAWPAW_BUILDDIR}/qtbase-everywhere-src-${QT5_VERSION}"
        touch "${PAWPAW_BUILDDIR}/qtbase-everywhere-src-${QT5_VERSION}/.stamp_configured"
        touch "${PAWPAW_BUILDDIR}/qtbase-everywhere-src-${QT5_VERSION}/.stamp_built"
        touch "${PAWPAW_BUILDDIR}/qtbase-everywhere-src-${QT5_VERSION}/.stamp_installed"
        touch "${PAWPAW_BUILDDIR}/qtbase-everywhere-src-${QT5_VERSION}/.stamp_applied_01_force-10.12-universal-build.patch"
        mkdir "${PAWPAW_BUILDDIR}/qtmacextras-everywhere-src-${QT5_VERSION}"
        touch "${PAWPAW_BUILDDIR}/qtmacextras-everywhere-src-${QT5_VERSION}/.stamp_configured"
        touch "${PAWPAW_BUILDDIR}/qtmacextras-everywhere-src-${QT5_VERSION}/.stamp_built"
        touch "${PAWPAW_BUILDDIR}/qtmacextras-everywhere-src-${QT5_VERSION}/.stamp_installed"
        mkdir "${PAWPAW_BUILDDIR}/qtsvg-everywhere-src-${QT5_VERSION}"
        touch "${PAWPAW_BUILDDIR}/qtsvg-everywhere-src-${QT5_VERSION}/.stamp_configured"
        touch "${PAWPAW_BUILDDIR}/qtsvg-everywhere-src-${QT5_VERSION}/.stamp_built"
        touch "${PAWPAW_BUILDDIR}/qtsvg-everywhere-src-${QT5_VERSION}/.stamp_installed"
        mkdir "${PAWPAW_BUILDDIR}/qttools-everywhere-src-${QT5_VERSION}"
        touch "${PAWPAW_BUILDDIR}/qttools-everywhere-src-${QT5_VERSION}/.stamp_configured"
        touch "${PAWPAW_BUILDDIR}/qttools-everywhere-src-${QT5_VERSION}/.stamp_built"
        touch "${PAWPAW_BUILDDIR}/qttools-everywhere-src-${QT5_VERSION}/.stamp_installed"
        pushd "${PAWPAW_DIR}/targets/${TARGET}"
        curl -L "https://falktx.com/data/pawpaw-qt-macos-universal.tar.xz" -o "pawpaw-qt-macos-universal.tar.xz" --fail
        tar xvf pawpaw-qt-macos-universal.tar.xz
        popd
    fi
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-qt.sh ${TARGET}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${TARGET}
    exit 0
fi

${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-carla.sh ${TARGET}
${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${TARGET}

if [ ${BUILD_VERSION} -eq 3 ]; then
    exit 0
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
make EXTERNAL_PLUGINS=false ${MAKE_ARGS}
if [ "${WIN64}" -eq 1 ]; then
make EXTERNAL_PLUGINS=false ${MAKE_ARGS} win32r
fi
make dist
popd

# ---------------------------------------------------------------------------------------------------------------------

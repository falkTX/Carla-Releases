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
# check if building from scratch

if [ -e ${PAWPAW_BUILDDIR}/.last-bootstrap-version ]; then
    LAST_BOOTSTRAP_VERSION=$(cat ${PAWPAW_BUILDDIR}/.last-bootstrap-version)
else
    LAST_BOOTSTRAP_VERSION=0
fi

mkdir -p ${PAWPAW_BUILDDIR}
echo ${BOOTSTRAP_VERSION} > ${PAWPAW_BUILDDIR}/.last-bootstrap-version

# ---------------------------------------------------------------------------------------------------------------------
# stop at qt build if bootstrap environment starts from scratch

if [ ${LAST_BOOTSTRAP_VERSION} -ne ${BOOTSTRAP_VERSION} ]; then
    ${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-qt.sh ${TARGET}
    ${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${TARGET}
    exit 0
fi

# ---------------------------------------------------------------------------------------------------------------------
# build dependencies

${TRAVIS_BUILD_DIR}/PawPaw/bootstrap-carla.sh ${TARGET}
${TRAVIS_BUILD_DIR}/PawPaw/.cleanup.sh ${TARGET}

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

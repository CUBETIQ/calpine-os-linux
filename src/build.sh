#!/bin/sh
#
# Copyright (c) 2021 Sambo Chea <sombochea@cubetiqs.com
# MIT
#

# Catch errors
set -ex

# Default args
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-calpine-os-linux}
DOCKER_USERNAME="${DOCKER_USERNAME:-cubetiq}"
ALPINE_VERSION="${ALPINE_VERSION:-3.15}"
PACKAGES="apk-tools ca-certificates ssl_client"

MKROOTFS="/tmp/alpine-make-rootfs"
BUILD_TAR="/tmp/calpine-os-linux-build/alpine-rootfs-${ALPINE_VERSION}.tar.gz"
DOCKER_ROOT=$(dirname $BUILD_TAR)
PRE_INSTALL="./src/pre-install.sh"
POST_INSTALL="./src/post-install.sh"

mkdir -p $DOCKER_ROOT

# Load pre-install
$PRE_INSTALL

# Build from alpine rootfs
# Download rootfs builder and verify it.
wget https://raw.githubusercontent.com/alpinelinux/alpine-make-rootfs/v0.6.0/alpine-make-rootfs -O "$MKROOTFS"
echo "c9cfea712709df162f4dcf26e2b1422aadabad43 $MKROOTFS" | sha1sum -c -
chmod +x ${MKROOTFS}

sudo ${MKROOTFS} --mirror-uri http://dl-2.alpinelinux.org/alpine \
	--branch "v${ALPINE_VERSION}" \
	--packages "$PACKAGES" \
	--script-chroot \
	"$BUILD_TAR" \
	"$POST_INSTALL"

# Create Dockerfile
cat <<DOCKERFILE > "${DOCKER_ROOT}/Dockerfile"
FROM scratch
LABEL maintainer="sombochea@cubetiqs.com"
USER cubetiq
ADD $(basename $BUILD_TAR) /
CMD ["/bin/sh"]
DOCKERFILE

cd $DOCKER_ROOT
docker build --no-cache -t "${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${ALPINE_VERSION}" .
cd -

# Scanner for docker build docker for security for os container
docker build --build-arg BASE_IMAGE="${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${ALPINE_VERSION}" --build-arg MS_TOKEN="${MS_TOKEN}" - <<'DOCKERFILE'
ARG BASE_IMAGE
FROM $BASE_IMAGE

DOCKERFILE
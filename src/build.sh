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
ALPINE_VERSION="${ALPINE_VERSION:-3.13.3}"
PACKAGES="apk-tools ca-certificates ssl_client"

MKROOTFS="/tmp/alpine-make-rootfs"
BUILD_TAR="/tmp/docker/alpine-rootfs-${ALPINE_VERSION}.tar.gz"
DOCKER_ROOT=$(dirname $BUILD_TAR)
PRE_INSTALL="./src/pre-install.sh"
POST_INSTALL="./src/post-install.sh"

mkdir $DOCKER_ROOT
MS_ROOT="${DOCKER_ROOT}/../microscanner"
mkdir $MS_ROOT

# Load pre-install
$PRE_INSTALL

# Build from alpine rootfs
# Download rootfs builder and verify it.
wget https://raw.githubusercontent.com/alpinelinux/alpine-make-rootfs/v0.5.1/alpine-make-rootfs -O "$MKROOTFS"
echo "a7159f17b01ad5a06419b83ea3ca9bbe7d3f8c03 $MKROOTFS" | sha1sum -c -
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
ARG MS_TOKEN
RUN wget https://get.aquasec.com/microscanner -O /home/cubetiq/microscanner \
  && echo "8e01415d364a4173c9917832c2e64485d93ac712a18611ed5099b75b6f44e3a5  /home/cubetiq/microscanner" | sha256sum -c - \
  && chmod +x /home/cubetiq/microscanner \
  && /home/cubetiq/microscanner $MS_TOKEN
DOCKERFILE
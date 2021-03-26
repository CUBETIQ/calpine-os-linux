#!/bin/sh
#
# Copyright (c) 2021 Sambo Chea <sombochea@cubetiqs.com
# MIT
#

set -ex
DOCKER_USERNAME="${DOCKER_USERNAME:-cubetiq}"
ALPINE_VERSION="${ALPINE_VERSION:-3.13.3}"
PACKAGES="apk-tools ca-certificates ssl_client"

MKROOTFS="/tmp/alpine-make-rootfs"
BUILD_TAR="/tmp/docker/alpine-rootfs-${ALPINE_VERSION}.tar.gz"
DOCKER_ROOT=$(dirname $BUILD_TAR)
PRE_INSTALL="./pre-install.sh"
POST_INSTALL="./post-install.sh"

mkdir $DOCKER_ROOT
MS_ROOT="${DOCKER_ROOT}/../microscanner"
mkdir $MS_ROOT

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
USER worker
ADD $(basename $BUILD_TAR) /
CMD ["/bin/sh"]
DOCKERFILE

cd $DOCKER_ROOT
docker build --no-cache -t "${DOCKER_USERNAME}/alpine:${ALPINE_VERSION}" .
cd -

docker build  --build-arg BASE_IMAGE="${DOCKER_USERNAME}/alpine:${ALPINE_VERSION}" --build-arg MS_TOKEN="${MS_TOKEN}" - <<'DOCKERFILE'
ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG MS_TOKEN
RUN wget https://get.aquasec.com/microscanner -O /home/worker/microscanner \
  && echo "8e01415d364a4173c9917832c2e64485d93ac712a18611ed5099b75b6f44e3a5  /home/worker/microscanner" | sha256sum -c - \
  && chmod +x /home/worker/microscanner \
  && /home/worker/microscanner $MS_TOKEN
DOCKERFILE
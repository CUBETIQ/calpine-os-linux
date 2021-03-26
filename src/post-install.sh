#!/bin/sh
#
# Copyright (c) 2021 Sambo Chea <sombochea@cubetiqs.com
# MIT
#

# Catch errors
set -ex

# Ensure certs are up to date
update-ca-certificates

# make saure we have the latest packages
/sbin/apk update
/sbin/apk upgrade

# Allow run sudo
/sbin/apk add sudo

# Add wheel group
echo '%wheel ALL=NOPASSWD: ALL' > /etc/sudoers.d/wheel

cat /etc/sudoers.d/wheel

# Add an administrator user.
adduser cubetiq wheel
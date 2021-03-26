#!/bin/sh
#
# Copyright (c) 2021 Sambo Chea <sombochea@cubetiqs.com
# MIT
#

echo "Post-installation..."

# Catch errors
set -ex

# Ensure certs are up to date
update-ca-certificates

# make saure we have the latest packages
/sbin/apk update
/sbin/apk upgrade

# Add a standard user.
adduser -D -u1000 cubetiq
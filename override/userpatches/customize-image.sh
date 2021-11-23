#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	export DEBIAN_FRONTEND=noninteractive

	# reconfigure tzdata
	timedatectl set-timezone "Asia/Shanghai"
	dpkg-reconfigure tzdata

	# fonts-noto-cjk
	apt install -y fonts-noto-cjk

	# install OMV
	wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | bash

} # Main

Main "$@"

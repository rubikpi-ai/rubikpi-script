#!/bin/bash -e
#
# Helps you quickly enable RUBIK Pi's peripheral functions (CAM, AI, Audio, etc.)
#
# Author: Hongyang Zhao <hongyang.zhao@thundersoft.com>
#         Roger Shimizu <roger.shimizu@am.thundersoft.com>
#         Ashok Bhatia  <ashokb@qti.qualcomm.com>
#
# Copyright (c) 2025 Thundercomm America Corp.
#               2025 Qualcomm Technologies, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of the copyright owner nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Set '-x' only if the option is neither '-h' nor '--help'
if [ $# -ne 1 ] || [ $# -gt 0 -a "$1" != "-h" -a "$1" != "--help" ]; then
	set -x
fi

# Configuration used by the script
REPO_ENTRY="deb http://apt.thundercomm.com/rubik-pi-3/noble ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"	# TODO: Remove legacy
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
CAMERA_SETTINGS=/var/cache/camera/camxoverridesettings.txt
PORTS_MIRROR=/etc/apt/sources.list.d/ports-mirror.sources
VERSION=0.1
[ -d $(dirname $(realpath $0))/.git ] &&
	VERSION+=+$(git -C $(dirname $(realpath $0)) describe --always)

# Common user and home dir for the ubuntu
USER_NAME=ubuntu
USER_HOME=$(eval echo "~$USER_NAME")

# Usage function with colored output
usage() {
	set +x
	printf "\033[1;37mUsage:\033[0m\n"
	printf "  %s [options]\n" "$0"
	printf "\n"
	printf "\033[1;37mDescription:\033[0m\n"
	printf "  Helps you quickly enable RUBIK Pi's peripheral functions (CAM, AI, Audio, etc.)\n"
	printf "\n"
	printf "\033[1;37mOptions:\033[0m\n"
	printf "\033[1;37m  -h, --help\033[0m              Display this help message\n"
}

add_ppa()
{
	# TODO: Remove legacy
	sudo sed -i "/$HOST_ENTRY/d" /etc/hosts || true
	sudo sed -i '/apt.rubikpi.ai ppa main/d' /etc/apt/sources.list || true

	if ! grep -q "^[^#]*$REPO_ENTRY" /etc/apt/sources.list; then
		echo "$REPO_ENTRY" | sudo tee -a /etc/apt/sources.list >/dev/null
	fi

	# Add the GPG key for the RUBIK Pi PPA
	wget -qO - https://thundercomm.s3.dualstack.ap-northeast-1.amazonaws.com/uploads/web/rubik-pi-3/tools/key.asc | sudo tee /etc/apt/trusted.gpg.d/rubikpi3.asc

	sudo apt update
}

install_cam_ai_samples()
{
	sudo chown -R ubuntu /opt
	grep -qxF "$XDG_EXPORT" $USER_HOME/.bashrc || echo "$XDG_EXPORT" >> $USER_HOME/.bashrc
	sudo bash -c "grep -qxF '${XDG_EXPORT}' /root/.bashrc || echo '${XDG_EXPORT}' >> /root/.bashrc"
	sudo mkdir -p /var/cache/camera
	sudo sh -c "echo 'enableNCSService=FALSE' > $CAMERA_SETTINGS"
	add_cam_ai_pkgs
}

add_cam_ai_pkgs()
{
	# CAM/AI -- QCOM PPA
	PKG_LIST+=(
		gstreamer1.0-qcom-python-examples
		gstreamer1.0-qcom-sample-apps
		gstreamer1.0-tools
		libqnn-dev
		libsnpe-dev
		qcom-adreno1
		qcom-fastcv-binaries-dev
		qcom-libdmabufheap-dev
		qcom-sensors-test-apps
		qcom-video-firmware
		qnn-tools
		snpe-tools
		tensorflow-lite-qcom-apps
		weston-autostart
	)
}

add_rubikpi_pkgs()
{
	# Wiringrp -- RUBIK Pi PPA
	PKG_LIST+=(
		wiringrp
		wiringrp-python
	)
}

add_system_pkgs()
{
	PKG_LIST+=(
		ffmpeg
		net-tools
		python3-pip
		selinux-utils
		unzip
		v4l-utils
	)
}

install()
{
	sudo apt install -y ${PKG_LIST[@]}
	sudo apt install -y rubikpi3-cameras
	sudo apt upgrade -y
}

finalize()
{
	sync; sync; sync
	if [ $reboot -eq 1 ]; then
		echo "Setup completed. System will reboot in 10 seconds..."
		sleep 10
		sudo reboot
	fi
}

# Main execution logic
main() {
	echo "RUBIK Pi 3 Setup Script"
	echo "  Version $VERSION"
	echo "======================="

	local reboot=1

	# Parse arguments and execute accordingly
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h|--help)
				usage
				exit 0
				;;
			*)
				echo "Unknown option: $1"
				echo "Use --help for usage information"
				exit 1
				;;
		esac
		shift
	done

	add_ppa
	install_cam_ai_samples
	add_rubikpi_pkgs
	add_system_pkgs
	install
	finalize
	echo "Script completed successfully!"
}

# Start the script
main "$@"

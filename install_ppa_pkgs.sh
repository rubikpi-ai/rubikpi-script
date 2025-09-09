#!/bin/bash -e
#
# Helps you quickly enable RUBIK Pi's peripheral functions (CAM, AI, Audio, etc.)

# Set '-x' only if the option is neither '-h' nor '--help'
if [ $# -ne 1 ] || [ $# -gt 0 -a "$1" != "-h" -a "$1" != "--help" ]; then
	set -x
fi

#Configuration used by the script
REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
CAMERA_SETTINGS=/var/cache/camera/camxoverridesettings.txt
PORTS_MIRROR=/etc/apt/sources.list.d/ports-mirror.sources

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
	printf "\033[1;37m  --hostname=<name>\033[0m       Set system hostname to specified name\n"
	printf "\033[1;37m  --mirror=<URI>\033[0m          Update the ubuntu-ports mirror\n"
	printf "\033[1;37m  --reboot\033[0m                Reboot at the end of the process\n"
	printf "\033[1;37m  --uninstall\033[0m             Uninstall everything related to this script\n"
	printf "\n"
	printf "\033[1;37mExamples:\033[0m\n"
	printf "  %s                          # Install all pkgs\n" "$0"
	printf "  %s --hostname=mypi          # Install all pkgs, and set hostname\n" "$0"
	printf "  %s --reboot                 # Install all pkgs, and reboot\n" "$0"
	printf "  %s --reboot --hostname=mypi # Install all pkgs, set hostname, and reboot\n" "$0"
	printf "  %s --uninstall --reboot     # Uninstall all pkgs, and reboot\n" "$0"
	printf "\n"
	printf "\033[1;37mRegion mirrors for ubuntu-ports:\033[0m\n"
	printf "  %s --mirror=https://ftp.tsukuba.wide.ad.jp/Linux/ubuntu-ports\t# Japan mirror\n" "$0"
	printf "  %s --mirror=https://in.mirror.coganng.com/ubuntu-ports\t\t# India mirror\n" "$0"
	printf "  %s --mirror=https://mirror.csclub.uwaterloo.ca/ubuntu-ports\t# Canada mirror\n" "$0"
	printf "  %s --mirror=https://mirror.dogado.de/ubuntu-ports\t\t\t# Germany mirror\n" "$0"
	printf "  %s --mirror=https://mirror.hashy0917.net/ubuntu-ports\t\t# Japan mirror\n" "$0"
	printf "  %s --mirror=https://mirror.kumi.systems/ubuntu-ports\t\t# Austria mirror\n" "$0"
	printf "  %s --mirror=https://mirror.twds.com.tw/ubuntu-ports\t\t# Taiwan mirror\n" "$0"
	printf "  %s --mirror=https://mirrors.mit.edu/ubuntu-ports\t\t\t# US/East mirror\n" "$0"
	printf "  %s --mirror=https://mirrors.ocf.berkeley.edu/ubuntu-ports\t\t# US/West mirror\n" "$0"
	printf "  %s --mirror=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports\t# China mirror\n" "$0"
	printf "  %s --mirror=https://mirrors.ustc.edu.cn/ubuntu-ports\t\t# China mirror\n" "$0"
}

add_ppa()
{
	if ! grep -q "^[^#]*$REPO_ENTRY" /etc/apt/sources.list; then
		echo "$REPO_ENTRY" | sudo tee -a /etc/apt/sources.list >/dev/null
	fi
	if ! grep -q "$HOST_ENTRY" /etc/hosts; then
		echo "$HOST_ENTRY" | sudo tee -a /etc/hosts >/dev/null
	fi

	# Add the GPG key for the apt.rubikpi.ai PPA
	wget -qO - https://thundercomm.s3.dualstack.ap-northeast-1.amazonaws.com/uploads/web/rubik-pi-3/tools/key.asc | sudo tee /etc/apt/trusted.gpg.d/rubikpi3.asc

	sudo apt update
}

remove_ppa()
{
	sudo sed -i '/apt.rubikpi.ai ppa main/d' /etc/apt/sources.list
	sudo sed -i "/$HOST_ENTRY/d" /etc/hosts
	sudo rm -f /etc/apt/trusted.gpg.d/rubikpi3.asc
}

update_mirror()
{
	cat > ports.sources << EOL
Types: deb
URIs: $1
Suites: noble noble-updates noble-backports noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOL
	sudo mv ports.sources $PORTS_MIRROR
	sudo chown root:root $PORTS_MIRROR
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

uninstall()
{
	set_hostname ubuntu
	sudo rm -f $CAMERA_SETTINGS $PORTS_MIRROR
	sed -i '/export XDG_RUNTIME_DIR=/d' $USER_HOME/.bashrc
	sudo sed -i '/export XDG_RUNTIME_DIR=/d' /root/.bashrc
	remove_ppa
	sudo apt update
	sudo apt purge -y ${PKG_LIST[@]} rubikpi3-cameras
	sudo apt autoremove --purge -y
}

set_hostname()
{
	sudo hostnamectl set-hostname $1 2>&1 > /dev/null
	sudo sed -i "s/^127\.0\.0\.1\s\+.*/127.0.0.1 localhost $1/" /etc/hosts 2>&1 > /dev/null
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
	echo "======================="

	local hostname=RUBIKPi3
	local uninstall=0
	local reboot=0

	# Parse arguments and execute accordingly
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h|--help)
				usage
				exit 0
				;;
			--hostname=*)
				hostname="${1#*=}"
				if [ -z "$hostname" ]; then
					echo "Error: hostname cannot be empty"
					exit 1
				fi
				set_hostname $hostname
				;;
			--mirror=*)
				mirror="${1#*=}"
				if [ -z "$mirror" ]; then
					echo "Error: mirror cannot be empty"
					exit 1
				fi
				update_mirror $mirror
				;;
			--reboot)
				reboot=1
				;;
			--uninstall)
				uninstall=1
				;;
			*)
				echo "Unknown option: $1"
				echo "Use --help for usage information"
				exit 1
				;;
		esac
		shift
	done

	if [ $uninstall -eq 1 ]; then
		add_cam_ai_pkgs
		add_rubikpi_pkgs
		add_system_pkgs
		uninstall
	else
		add_ppa
		install_cam_ai_samples
		add_rubikpi_pkgs
		add_system_pkgs
		install
	fi

	finalize
	echo "Script completed successfully!"
}

# Start the script
main "$@"

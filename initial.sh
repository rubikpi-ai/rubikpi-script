#!/bin/bash
set -e

REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
CAMERA_SETTINGS="/var/cache/camera/camxoverridesettings.txt"
USER_HOME="/home/ubuntu"
USER_NAME="ubuntu"

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

	sudo apt update -y
}

camera_install()
{
	sudo mkdir -p /opt
	sudo chmod 755 /opt
	grep -qxF "$XDG_EXPORT" "$USER_HOME/.bashrc" || echo "$XDG_EXPORT" >> "$USER_HOME/.bashrc"
	sudo bash -c "grep -qxF '${XDG_EXPORT}' /root/.bashrc || echo '${XDG_EXPORT}' >> /root/.bashrc"
	sudo mkdir -p /var/cache/camera
	sudo sh -c "echo 'enableNCSService=FALSE' > $CAMERA_SETTINGS"

	# CAM/AI -- QCOM PPA
	sudo apt install -y \
		gstreamer1.0-qcom-sample-apps qcom-sensors-test-apps \
		gstreamer1.0-tools qcom-fastcv-binaries-dev qcom-video-firmware \
		weston-autostart libgbm-msm1 qcom-adreno1 qcom-ib2c qcom-camera-server \
		qcom-camx

	# CAM/wiringrp -- RUBIK Pi PPA
	sudo apt install -y \
		rubikpi3-cameras
}

rubikpi_software_install()
{
	sudo apt install -y \
		wiringrp wiringrp-python
}

# start of the script
add_ppa
camera_install
rubikpi_software_install

sudo apt upgrade -y

echo "Setup completed. System will reboot in 10 seconds..."
sleep 10
sudo reboot

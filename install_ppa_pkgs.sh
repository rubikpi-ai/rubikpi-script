#!/bin/bash -ex

#Configuration used by the script
REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
CAMERA_SETTINGS="/var/cache/camera/camxoverridesettings.txt"

# Common user and home dir for the ubuntu
USER_NAME=ubuntu
USER_HOME=$(eval echo "~$USER_NAME")

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

install_camera_pkgs()
{
	sudo chown -R ubuntu /opt
	grep -qxF "$XDG_EXPORT" "$USER_HOME/.bashrc" || echo "$XDG_EXPORT" >> "$USER_HOME/.bashrc"
	sudo bash -c "grep -qxF '${XDG_EXPORT}' /root/.bashrc || echo '${XDG_EXPORT}' >> /root/.bashrc"
	sudo mkdir -p /var/cache/camera
	sudo sh -c "echo 'enableNCSService=FALSE' > $CAMERA_SETTINGS"

	# CAM/AI -- QCOM PPA
	PKG_LIST+=( \
		gstreamer1.0-qcom-sample-apps \
		gstreamer1.0-tools \
		libgbm-msm1 \
		qcom-adreno1 \
		qcom-camera-server \
		qcom-camx \
		qcom-fastcv-binaries-dev \
		qcom-ib2c \
		qcom-sensors-test-apps \
		qcom-video-firmware \
		weston-autostart \
	)

	# Camera -- RUBIK Pi PPA (TODO: to be moved to Canonical PPA)
	PKG_LIST+=( \
		rubikpi3-cameras \
	)
}

install_rubikpi_pkgs()
{
	# Wiringrp -- RUBIK Pi PPA
	PKG_LIST+=( \
		wiringrp \
		wiringrp-python \
	)
}

install_system_pkgs()
{
	PKG_LIST+=( \
		net-tools \
		v4l-utils \
		unzip \
	)
}

# start of the script
add_ppa
install_camera_pkgs
install_rubikpi_pkgs
install_system_pkgs

sudo apt install -y ${PKG_LIST[@]}
sudo apt upgrade -y

echo "Setup completed. System will reboot in 10 seconds..."
sync; sync; sync
sleep 10
sudo reboot

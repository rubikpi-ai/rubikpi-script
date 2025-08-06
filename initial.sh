#!/bin/bash
set -e

REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
CAMERA_SETTINGS="/var/cache/camera/camxoverridesettings.txt"
USER_HOME="/home/ubuntu"
USER_NAME="ubuntu"


sudo add-apt-repository -yn ppa:ubuntu-qcom-iot/qcom-noble-ppa
if ! grep -q "^[^#]*$REPO_ENTRY" /etc/apt/sources.list; then
    echo "$REPO_ENTRY" | sudo tee -a /etc/apt/sources.list >/dev/null
fi
if ! grep -q "$HOST_ENTRY" /etc/hosts; then
    echo "$HOST_ENTRY" | sudo tee -a /etc/hosts >/dev/null
fi

wget -qO - https://thundercomm.s3.dualstack.ap-northeast-1.amazonaws.com/uploads/web/rubik-pi-3/tools/key.asc | sudo tee /etc/apt/trusted.gpg.d/rubikpi3.asc
sudo apt update -y


sudo mkdir -p /opt
sudo chmod 755 /opt
grep -qxF "$XDG_EXPORT" "$USER_HOME/.bashrc" || echo "$XDG_EXPORT" >> "$USER_HOME/.bashrc"
sudo bash -c "grep -qxF '${XDG_EXPORT}' /root/.bashrc || echo '${XDG_EXPORT}' >> /root/.bashrc"
sudo mkdir -p /var/cache/camera
sudo sh -c "echo 'enableNCSService=FALSE' > $CAMERA_SETTINGS"

# CAM/AI -- QCOM PPA
sudo apt install -y --no-install-recommends \
    gstreamer1.0-qcom-sample-apps qcom-sensors-test-apps \
    gstreamer1.0-tools qcom-fastcv-binaries-dev qcom-video-firmware \
    weston-autostart libgbm-msm1 qcom-adreno1 qcom-ib2c qcom-camera-server \
    qcom-camx

# CAM/wiringrp -- RUBIK Pi PPA
sudo apt install -y --no-install-recommends \
    rubikpi3-cameras wiringrp wiringrp-python

# Pulseaudio -- RUBIK Pi PPA
sudo apt install -y --no-install-recommends \
    libsndfile1 libltdl7 libspeexdsp1 qcom-fastrpc1 \
    rubikpi3-tinyalsa rubikpi3-tinycompress rubikpi3-qcom-agm \
    rubikpi3-qcom-args rubikpi3-qcom-pal rubikpi3-qcom-audio-ftm \
    rubikpi3-qcom-audioroute rubikpi3-qcom-acdbdata rubikpi3-qcom-audio-node \
    rubikpi3-qcom-kvh2xml rubikpi3-qcom-pa-bt-audio rubikpi3-qcom-sva-capi-uv-wrapper \
    rubikpi3-qcom-sva-cnn rubikpi3-qcom-sva-listen-sound-model rubikpi3-qcom-sva-eai \
    rubikpi3-qcom-pa-pal-voiceui rubikpi3-qcom-pa-pal-acd rubikpi3-qcom-audio-plugin-headers \
    rubikpi3-qcom-dac-mer-testapp rubikpi3-qcom-dac-plugin rubikpi3-qcom-mercury-plugin \
    rubikpi3-pulseaudio rubikpi3-diag rubikpi3-dsp rubikpi3-libdmabufheap \
    rubikpi3-qcom-vui-interface rubikpi3-qcom-vui-interface-header rubikpi3-time-genoff \
    rubikpi3-pa-pal-plugins

sudo usermod -aG audio,pulse,plugdev,video,render "$USER_NAME"

sudo apt upgrade -y

echo "Setup completed. System will reboot in 10 seconds..."
sleep 10
sudo reboot

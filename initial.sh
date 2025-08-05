#!/bin/bash

set -e

# CAM/AI     Ubuntu Server
sudo add-apt-repository -yn ppa:ubuntu-qcom-iot/qcom-noble-ppa
sudo sed -i '$a deb http://apt.rubikpi.ai ppa main' /etc/apt/sources.list
sudo chmod -R 777 /opt
sed -i '$a export XDG_RUNTIME_DIR=/run/user/$(id -u)' ~ubuntu/.bashrc
sudo sed -i '$a export XDG_RUNTIME_DIR=/run/user/$(id -u ubuntu)' /root/.bashrc
sudo mkdir -p /var/cache/camera
sudo sh -c 'echo enableNCSService=FALSE > /var/cache/camera/camxoverridesettings.txt'

sudo apt update

sudo apt install -y gstreamer1.0-qcom-sample-apps qcom-sensors-test-apps \
	gstreamer1.0-tools qcom-fastcv-binaries-dev qcom-video-firmware \
	weston-autostart libgbm-msm1 qcom-adreno1 qcom-ib2c qcom-camera-server \
	qcom-camx
sudo apt install -y rubikpi3-cameras wiringrp wiringrp-python

# Pulseaudio
sudo apt install -y libsndfile1 libltdl7 libspeexdsp1 qcom-fastrpc1 \
rubikpi3-tinyalsa rubikpi3-tinycompress rubikpi3-qcom-agm rubikpi3-qcom-args rubikpi3-qcom-pal \
rubikpi3-qcom-audio-ftm rubikpi3-qcom-audioroute rubikpi3-qcom-acdbdata rubikpi3-qcom-audio-node \
rubikpi3-qcom-kvh2xml rubikpi3-qcom-pa-bt-audio rubikpi3-qcom-sva-capi-uv-wrapper rubikpi3-qcom-sva-cnn \
rubikpi3-qcom-sva-listen-sound-model rubikpi3-qcom-sva-eai rubikpi3-qcom-pa-pal-voiceui rubikpi3-qcom-pa-pal-acd \
rubikpi3-qcom-audio-plugin-headers rubikpi3-qcom-dac-mer-testapp rubikpi3-qcom-dac-plugin rubikpi3-qcom-mercury-plugin \
rubikpi3-pulseaudio rubikpi3-diag rubikpi3-dsp rubikpi3-libdmabufheap rubikpi3-qcom-vui-interface rubikpi3-qcom-vui-interface-header \
rubikpi3-time-genoff rubikpi3-pa-pal-plugins
sudo usermod -aG audio,pulse,plugdev,video,render ubuntu  # Replace ubuntu with the actual user name

sudo apt upgrade -y

sudo reboot


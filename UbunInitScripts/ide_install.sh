#!/bin/bash
#Enable:
#  -x : Debugging Trace
#  -u : Uninitialized variable usage detection
#  -o pipefail : Return the first error code as the return value of the script
set -uxo pipefail
#But continue to complete the script, despite failures.
set +e


#Configuration used by the script
REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
WAYLAND_EXPORT="export WAYLAND_DISPLAY=wayland-1"
GBM_EXPORT="export GBM_BACKEND=msm"
GST_DBG_EXPORT="export GST_DEBUG=2"
CAMERA_SETTINGS="/var/cache/camera/camxoverridesettings.txt"

#Identifiers of the user who is running the script
USER_NAME=$(id -un)
USER_HOME=$(eval echo "~$USER_NAME")
USER_ID=$(id -u)


#Configuration used by the script
REPO_ENTRY="deb http://apt.rubikpi.ai ppa main"
HOST_ENTRY="151.106.120.85 apt.rubikpi.ai"
XDG_EXPORT="export XDG_RUNTIME_DIR=/run/user/\$(id -u)"
WAYLAND_EXPORT="export WAYLAND_DISPLAY=wayland-1"
GBM_EXPORT="export GBM_BACKEND=msm"
GST_DBG_EXPORT="export GST_DEBUG=2"
CAMERA_SETTINGS="/var/cache/camera/camxoverridesettings.txt"

#Identifiers of the user who is running the script
USER_NAME=$(id -un)
USER_HOME=$(eval echo "~$USER_NAME")
USER_ID=$(id -u)

# Suppress interactive prompts and auto-restart services
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
LOG_FILE="ide_initcfg.log"
STATE_FILE=".install_status.log"

# Root directory where all the Application artifacts are stored.
# Currently this is configured as /etc; as these directories need
# to be aligned with what the sample applications do. However, this
# should be changed to /local/etc.
APPLICATION_ARTIFACT_DIR="/etc"

#---------------------
# Below packages are listed in TC Init script. Should be all covered by the below
# Installs. But leaving this for reference.
# CAM/AI -- QCOM PPA
#sudo apt install -y --no-install-recommends \
#    gstreamer1.0-qcom-sample-apps qcom-sensors-test-apps \
#    gstreamer1.0-tools qcom-fastcv-binaries-dev qcom-video-firmware \
#    weston-autostart libgbm-msm1 qcom-adreno1 qcom-ib2c qcom-camera-server \
#    qcom-camx

# CAM/wiringrp -- RUBIK Pi PPA
#sudo apt install -y --no-install-recommends \
#    rubikpi3-cameras wiringrp wiringrp-python

# Pulseaudio -- RUBIK Pi PPA
#sudo apt install -y --no-install-recommends \
#    libsndfile1 libltdl7 libspeexdsp1 qcom-fastrpc1 \
#    rubikpi3-tinyalsa rubikpi3-tinycompress rubikpi3-qcom-agm \
#    rubikpi3-qcom-args rubikpi3-qcom-pal rubikpi3-qcom-audio-ftm \
#    rubikpi3-qcom-audioroute rubikpi3-qcom-acdbdata rubikpi3-qcom-audio-node \
#    rubikpi3-qcom-kvh2xml rubikpi3-qcom-pa-bt-audio rubikpi3-qcom-sva-capi-uv-wrapper \
#    rubikpi3-qcom-sva-cnn rubikpi3-qcom-sva-listen-sound-model rubikpi3-qcom-sva-eai \
#    rubikpi3-qcom-pa-pal-voiceui rubikpi3-qcom-pa-pal-acd rubikpi3-qcom-audio-plugin-headers \
#    rubikpi3-qcom-dac-mer-testapp rubikpi3-qcom-dac-plugin rubikpi3-qcom-mercury-plugin \
#    rubikpi3-pulseaudio rubikpi3-diag rubikpi3-dsp rubikpi3-libdmabufheap \
#    rubikpi3-qcom-vui-interface rubikpi3-qcom-vui-interface-header rubikpi3-time-genoff \
#    rubikpi3-pa-pal-plugins

#sudo usermod -aG audio,pulse,plugdev,video,render "$USER_NAME"
#--------------------

# Define packages that need to be installed
#Not added qcom-diag-router,qcom-iot-defaults from https://confluence.qualcomm.com/confluence/display/CICT/Canonical+Bringup
# Core tools and utilities
APT_PACKAGES_CORE=(
  "git"
  "pip"
  "net-tools"
  "android-tools-adb"
  "adbd"
  "lrzsz"
  "gdbserver"
  "selinux-utils"
)
APT_PACKAGES_MULTIMEDIA=(
  "pulseaudio-module-pal-card"
  "weston-qcom"
  "weston-autostart"
  "qcom-camera-server"
  "qcom-camx"
  "libgbm-msm1"
  "camx-kt"
  "qcom-video-firmware"
  "qcom-fastcv-binaries-dev"
  "gstreamer1.0"
  "gstreamer1.0-tools"
  "gstreamer1.0-plugins-qcom-tools"
  "gstreamer1.0-plugins-qcom"
  "gstreamer1.0-qcom-sample-apps"
)
# Qualcomm-specific and hardware packages
# SNPE, QNN for AI; IB2C for I2C Communincation, Aderno for GPU
# and sensor test applications
APT_PACKAGES_QCOM=(
  "libsnpe1"
  "libqnn1"
  "qcom-ib2c"
  "qcom-adreno1"
  "qcom-sensors-test-apps"
)
APT_PACKAGES_RPI=(
  "rubikpi3-cameras"
  "wiringrp"
  "wiringrp-python"
)
APT_PACKAGES_RPI_PULSE_AUDIO=(
    "libsndfile1" "libltdl7" "libspeexdsp1" "qcom-fastrpc1" "rubikpi3-tinyalsa" "rubikpi3-tinycompress" "rubikpi3-qcom-agm"
    "rubikpi3-qcom-args" "rubikpi3-qcom-pal" "rubikpi3-qcom-audio-ftm"
    "rubikpi3-qcom-audioroute" "rubikpi3-qcom-acdbdata" "rubikpi3-qcom-audio-node"
    "rubikpi3-qcom-kvh2xml" "rubikpi3-qcom-pa-bt-audio" "rubikpi3-qcom-sva-capi-uv-wrapper"
    "rubikpi3-qcom-sva-cnn" "rubikpi3-qcom-sva-listen-sound-model" "rubikpi3-qcom-sva-eai"
    "rubikpi3-qcom-pa-pal-voiceui" "rubikpi3-qcom-pa-pal-acd" "rubikpi3-qcom-audio-plugin-headers"
    "rubikpi3-qcom-dac-mer-testapp" "rubikpi3-qcom-dac-plugin" "rubikpi3-qcom-mercury-plugin"
    "rubikpi3-pulseaudio" "rubikpi3-diag" "rubikpi3-dsp" "rubikpi3-libdmabufheap"
    "rubikpi3-qcom-vui-interface" "rubikpi3-qcom-vui-interface-header" "rubikpi3-time-genoff"
    "rubikpi3-pa-pal-plugins"
)

APT_PACKAGES=("${APT_PACKAGES_CORE[@]}" "${APT_PACKAGES_QCOM[@]}" "${APT_PACKAGES_MULTIMEDIA[@]}" "${APT_PACKAGES_RPI[@]}"
#    "${APT_PACKAGES_RPI_PULSE_AUDIO[@]}"  #Exclude the Pulse Audio Packages. This will be replaced by Pipewire
)

# Define Service packages that need to be installed
# Fot the packages in this category, after the APT
# install, the systemctl start and systemctl enable
# will also be done
APT_SVC_PACKAGES=("avahi-daemon"  )
PIP_PACKAGES=("debugpy" )

# Initialize state file if not present
touch "$STATE_FILE"

# Function to check if a package is marked installed
is_installed() {
  grep -qx "$1:success" "$STATE_FILE"
}

# Function to mark status
mark_status() {
  sed -i "/^$1:/d" "$STATE_FILE"
  echo "$1:$2" >> "$STATE_FILE"
}

# Function to install ADBD
install_adbd() {
  #if is_installed "arm64-adbd"; then
  if true; then
    sudo dpkg -i adbd_5.1.1.r37-11_arm64.deb
    echo "✅ arm64-adbd already installed."
  else
    #Package: android-tools-adbd
    #Pin: version 5.1.1.r38-1.1
    #Pin-Priority: 1001
    # Add bionic-proposed if not already present

    # Replace archive.ubuntu.com with ports.ubuntu.com
    sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://ports.ubuntu.com/ubuntu-ports|g' /etc/apt/sources.list

    # Add bionic-proposed if it's not already present
    if ! grep -q "bionic-proposed" /etc/apt/sources.list; then
      echo "deb http://ports.ubuntu.com/ubuntu-ports bionic-proposed main universe multiverse restricted" | sudo tee -a /etc/apt/sources.list > /dev/null
    fi



    #if ! grep -q "^deb .*bionic-proposed" /etc/apt/sources.list; then
    #  echo "deb http://archive.ubuntu.com/ubuntu bionic-proposed universe" | sudo tee -a /etc/apt/sources.list
    #fi

    # Create the preferences file if it doesn't exist
    sudo touch /etc/apt/preferences.d/android-tools-adbd

    # Remove any existing block for android-tools-adbd to avoid duplicates
    sudo sed -i '/^Package: android-tools-adbd$/,/^Pin-Priority:/d' /etc/apt/preferences.d/android-tools-adbd

    # Append the new pinning block
    {
      echo "Package: android-tools-adbd"
      echo "Pin: version 5.1.1.r38-1.1"
      echo "Pin-Priority: 1001"
    } | sudo tee -a /etc/apt/preferences.d/android-tools-adbd > /dev/null
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
    sudo apt update
    sudo apt install -y android-tools-adbd=5.1.1.r38-1.1
    mark_status "arm64-adbd" "success"
    echo "PPA arm64-adbd added" | tee -a $LOG_FILE
  fi
}


#Script Version Info: Update it when making changes
ScriptVersionInfo="RubikPi InitConfig Script - V1.3 Date: 08/20/2025 author: Ashok Bhatia"
# Check if a new hostname has been supplied
HOSTNAME=""
# Parse command-line arguments
for arg in "$@"; do
  case $arg in
    --hostname=*)
      HOSTNAME="${arg#*=}"
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# If hostname is set, call sethostname.sh with it
# so that when avahi-daemon is run later in the script
# the device becomes addressable by device name
if [ -n "$HOSTNAME" ]; then
  ./sethostname.sh "$HOSTNAME"
fi


# First update the APT
#sudo -E apt-get update
##From: https://launchpad.net/~ubuntu-qcom-iot
#TMP sudo apt-add-repository --login ppa:carmel-team/carmel-build
if is_installed "repo-noble-ppa"; then
    echo "✅ Repo noble-ppa already installed."
else
  sudo add-apt-repository -y ppa:ubuntu-qcom-iot/qcom-noble-ppa
  mark_status "repo-noble-ppa" "success"
  echo "PPA qcom-noble added" | tee -a $LOG_FILE
fi
if is_installed "repo-qcom-ppa"; then
    echo "✅ Repo qcom-ppa already installed."
else
  sudo add-apt-repository -y ppa:ubuntu-qcom-iot/qcom-ppa
  mark_status "repo-qcom-ppa" "success"
  echo "PPA ubuntu-qcom-iot added" | tee -a $LOG_FILE
fi
if is_installed "repo-qirp-ppa"; then
    echo "✅ Repo qirp-ppa already installed."
else
  sudo add-apt-repository -y ppa:ubuntu-qcom-iot/qirp
  mark_status "repo-qirp-ppa" "success"
  echo "PPA repo-qirp-ppa added" | tee -a $LOG_FILE
fi
#Rubik-PI PPA
if is_installed "repo-rpi-ppa"; then
    echo "✅ Repo rubikpi-ppa already installed."
else
  if ! grep -q "$HOST_ENTRY" /etc/hosts; then
    echo "$HOST_ENTRY" | sudo tee -a /etc/hosts >/dev/null
  fi
  if ! grep -q "^[^#]*$REPO_ENTRY" /etc/apt/sources.list; then
    echo "Skipping RPI-PPA"
    echo "$REPO_ENTRY" | sudo tee -a /etc/apt/sources.list >/dev/null
  fi
  wget -qO - https://thundercomm.s3.dualstack.ap-northeast-1.amazonaws.com/uploads/web/rubik-pi-3/tools/key.asc | sudo tee /etc/apt/trusted.gpg.d/rubikpi3.asc
  mark_status "repo-rpi-ppa" "success"
  echo "PPA repo-rpi-ppa added" | tee -a $LOG_FILE
fi

install_adbd

sudo apt update -y | tee -a $LOG_FILE
sudo apt upgrade -y | tee -a $LOG_FILE
echo "APT Update and Upgraded" | tee -a $LOG_FILE

echo "📦 Installing APT packages..."
for pkg in "${APT_PACKAGES[@]}"; do
  if is_installed "apt-$pkg"; then
    echo "✅ APT $pkg already installed."
    continue
  fi

  if [[ "$pkg" == "weston"* ]]; then
    #Check if weeston is running already and if yes, just skip
    if pgrep -x weston > /dev/null; then
      continue
    fi
  fi
  if sudo -E apt-get install -y "$pkg"; then
    #weston-autostart many times requires dpkg reconfigure
    if [[ "$pkg" == "weston-autostart" ]]; then
      sudo dpkg-reconfigure weston-autostart
      echo "Reconfigure Weston-autostart" | tee -a $LOG_FILE
    fi
    echo "✅ APT $pkg installed."
    mark_status "apt-$pkg" "success"
    echo "APT apt-$pkg Installed" >> $LOG_FILE
  else
    echo "❌ APT $pkg failed."
    mark_status "apt-$pkg" "fail"
    echo "APT apt-$pkg Failed" >> $LOG_FILE
  fi
done
for pkg in "${APT_SVC_PACKAGES[@]}"; do
  if is_installed "apt-$pkg"; then
    echo "✅ APT $pkg already installed."
    continue
  fi

  if sudo -E apt-get install -y "$pkg"; then
    echo "✅ APT $pkg installed." | tee -a $LOG_FILE
    mark_status "apt-$pkg" "success"
    echo "Starting $pkg Service"
    sudo systemctl start $pkg
    sudo systemctl enable $pkg
    echo "Svc for $pkg Started and reenabled"|tee -a $LOG_FILE
  else
    echo "❌ APT $pkg failed."|tee -a $LOG_FILE
    mark_status "apt-$pkg" "fail"
  fi
done

echo "🐍 Installing PIP packages..."
for pkg in "${PIP_PACKAGES[@]}"; do
  if is_installed "pip-$pkg"; then
    echo "✅ PIP $pkg already installed."
    continue
  fi

  if sudo apt install -y "python3-$pkg"; then
    echo "✅ apt  python3-$pkg installed."|tee -a $LOG_FILE
    mark_status "pip-$pkg" "success"
  else
    echo "❌ PIP $pkg failed."|tee -a $LOG_FILE
    mark_status "pip-$pkg" "fail"
  fi
done

if is_installed "misc-pkgs"; then
    echo "✅ misc pkgs already installed."
else
  ./dloadpkgs.sh
  mark_status "misc-pkgs" "success"
  echo "✅ misc pkgs installed."|tee -a $LOG_FILE
fi


#These needs to be done everytime a new shell is started
#So, configure these steps in the .bashrc
if is_installed "xdg-config"; then
  echo "XDG Config already done"|tee -a $LOG_FILE
else
  #Add lines in .bashrc to set XDG_RUNTIME_DIR
  grep -qxF "$XDG_EXPORT" "$USER_HOME/.bashrc" || echo "$XDG_EXPORT" >> "$USER_HOME/.bashrc"
  sudo bash -c "grep -qxF '${XDG_EXPORT}' /root/.bashrc || echo '${XDG_EXPORT}' >> /root/.bashrc"

  #Add lines in .bashrc to set WAYLAND_DISPLAY
  grep -qxF "$WAYLAND_EXPORT" "$USER_HOME/.bashrc" || echo "$WAYLAND_EXPORT" >> "$USER_HOME/.bashrc"
  sudo bash -c "grep -qxF '${WAYLAND_EXPORT}' /root/.bashrc || echo '${WAYLAND_EXPORT}' >> /root/.bashrc"

  #Add lines in .bashrc to set GBM_BACKEND to msm
  grep -qxF "$GBM_EXPORT" "$USER_HOME/.bashrc" || echo "$GBM_EXPORT" >> "$USER_HOME/.bashrc"
  sudo bash -c "grep -qxF '${GBM_EXPORT}' /root/.bashrc || echo '${GBM_EXPORT}' >> /root/.bashrc"

  #Add lines in .bashrc to set GST_DEBUG to GST_DEBUG_LEVEL
  grep -qxF "$GST_DBG_EXPORT" "$USER_HOME/.bashrc" || echo "$GST_DBG_EXPORT" >> "$USER_HOME/.bashrc"
  sudo bash -c "grep -qxF '${GST_DBG_EXPORT}' /root/.bashrc || echo '${GST_DBG_EXPORT}' >> /root/.bashrc"

  #And finally, ensure that XDG_RUNTIME_DIR has been created
  XDG_RUNTIME_DIR=/run/user/$USER_ID
  sudo mkdir -p $XDG_RUNTIME_DIR

  #Mark the status of these configurations
  mark_status "xdg-config" "success"
  echo "XDG and Wayland configured"|tee -a $LOG_FILE
fi

#And, for this shell (where script is executing), set these export variables
sudo -i export XDG_RUNTIME_DIR=/run/user/$(id -u)
sudo -i export WAYLAND_DISPLAY=wayland-1
sudo -i export GBM_BACKEND=msm
sudo -i export GST_DEBUG=2
if pgrep -x weston > /dev/null; then
  echo "weston is already running."|tee -a $LOG_FILE
else
  sudo nohup weston --continue-without-input --idle-time=0&
  echo "Weston Started"|tee -a $LOG_FILE
fi

#Enable Camera - One time setting only
if is_installed "camx-config"; then
  echo "Camx Already configured"|tee -a $LOG_FILE
else
  CAMERA_SETTINGS_DIR=$(dirname "$CAMERA_SETTINGS")
  sudo mkdir -p $CAMERA_SETTINGS_DIR
  sudo touch $CAMERA_SETTINGS
  echo "enableNCSService=FALSE" | sudo tee $CAMERA_SETTINGS > /dev/null
  mark_status "camx-config" "success"
  echo "Camx configured"|tee -a $LOG_FILE
fi

if is_installed "user_groups"; then
  echo "User Groups for ${USER_NAME} Already configured"|tee -a $LOG_FILE
else
  #Add user to the groups
  sudo usermod -aG audio,pulse,plugdev,video,render "$USER_NAME"
  mark_status "user_groups" "success"
  echo "User Groups for user ${USER_NAME} configured"|tee -a $LOG_FILE
fi
echo "$ScriptVersionInfo"
echo "📝 Installation status:"
cat "$STATE_FILE"

##Create or provide write permissions to the directories where
##AI Models, Labels and other artifacts needed for the application
##will be stored.
sudo mkdir -p /opt
sudo chmod -R 755 /opt
sudo mkdir -p "$APPLICATION_ARTIFACT_DIR/configs"
sudo chmod a+rw -R  "$APPLICATION_ARTIFACT_DIR/configs"
sudo mkdir -p "$APPLICATION_ARTIFACT_DIR/models"
sudo chmod a+rw -R "$APPLICATION_ARTIFACT_DIR/models"
sudo mkdir -p "$APPLICATION_ARTIFACT_DIR/labels"
sudo chmod a+rw -R "$APPLICATION_ARTIFACT_DIR/labels"
sudo mkdir -p "$APPLICATION_ARTIFACT_DIR/media"
sudo chmod a+rw -R "$APPLICATION_ARTIFACT_DIR/media"



### THIS IS THE LAST PART OF THE SCRIPT. ALL CONFIGURATIONS MUST BE DONE
### before this section.
###System Reboot. Need to consider if this must be done always, or should
###the script ask for user input. Currently this is dependent upon the caller
###supplying --reboot command line option
echo "Setup completed."
# Check if --reboot is among the arguments
reboot_sys=false
if [[ " $* " == *" --reboot "* ]]; then
  echo "System will reboot in 10 seconds"
  reboot_sys=true
else
  read -p "Do you want to reboot the system now? (Y/N): " response
  if [[ "$response" == "Y" || "$response" == "y" ]]; then
    echo "System will reboot in 10 seconds"
    reboot_sys=true
  else
    echo "Proceeding without reboot."
    echo "Warning !! Some configurations may not work until next reboot"
  fi
fi

if $reboot_sys; then
  sleep 10
  sudo reboot
fi

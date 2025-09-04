#!/bin/bash

# Download directory
DOWNLOAD_DIR="./qcom-noble-debs"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# Base URL for the PPA
BASE_URL="https://launchpad.net/~ubuntu-qcom-iot/+archive/ubuntu/qcom-noble-ppa/+files"

# List of package filenames
# This list was provided by various tests run to ensure that EI Model workflows
# can run on Ubuntu builds on RPI-3.
FILES=(
  "libqnn-dev_2.34.0.250424-0ubuntu1_arm64.deb"
  "libqnn1_2.34.0.250424-0ubuntu1_arm64.deb"
  "libsnpe-dev_2.34.0.250424-0ubuntu1_arm64.deb"
  "libsnpe1_2.34.0.250424-0ubuntu1_arm64.deb"
  "qcom-fastrpc-dev_1.0.0-7_arm64.deb"
  "qcom-fastrpc1_1.0.0-7_arm64.deb"
  "qcom-libdmabufheap-dev_1.1.0+250131+rel1.0+nmu1_arm64.deb"
  "qcom-libdmabufheap_1.1.0+250131+rel1.0+nmu1_arm64.deb"
  "qnn-tools_2.34.0.250424-0ubuntu1_arm64.deb"
  "snpe-tools_2.34.0.250424-0ubuntu1_arm64.deb"
)

# Download each file
for FILE in "${FILES[@]}"; do
  echo "Downloading $FILE..."
  wget "$BASE_URL/$FILE"
done

echo "✅ All files downloaded to $DOWNLOAD_DIR"
sudo dpkg -i *.deb

cd ..
wget https://cdn.edgeimpulse.com/firmware/linux/setup-edge-impulse-qc-linux.sh
chmod a+x setup-edge-impulse-qc-linux.sh
./setup-edge-impulse-qc-linux.sh

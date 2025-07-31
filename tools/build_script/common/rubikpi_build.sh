#!/bin/sh
# Author: Zhao Hongyang <hongyang.zhao@thundersoft.com>
# Date: 2024-11-15
# Copyright (c) 2024, Thundercomm All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
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
#

set -e

BOOTIMG_EXTRA_SPACE="512"
BOOTIMG_VOLUME_ID="BOOT"
TOP_DIR=`pwd`
KERNEL_CONFIG="qcom_defconfig"
CONFIG_FILE_DIR="${TOP_DIR}/arch/arm64/configs"
KERNEL_CONFIG_FRAGMENTS="${CONFIG_FILE_DIR}/qcom_addons.config \
						 ${CONFIG_FILE_DIR}/selinux.cfg \
						 ${CONFIG_FILE_DIR}/smack.cfg \
						 ${CONFIG_FILE_DIR}/rubikpi3.config"
KERNEL_INCLUDE="${TOP_DIR}/include/"

usage() {
	echo "\033[1;37mUsage:\033[0m"
	echo "  bash $0 [options]"
	echo
	echo "\033[1;37mOptions:\033[0m"
	echo "\033[1;37m  -h, --help\033[0m              display this help message"
	echo "\033[1;37m  -dp, --dtb_package\033[0m      generate a burnable device tree image"
	echo "\033[1;37m  -ip, --image_package\033[0m    generate a burnable kernel image"
	echo "\033[1;37m  -a, --build_all\033[0m         Complete compilation of kernel"
	echo "\033[1;37m  -d, --build_dts\033[0m         Complete compilation of device tree"
	echo "\033[1;37m  -gc, --generate_config\033[0m  Generate. config file"
	echo "\033[1;37m  -c, --clean\033[0m             Clean up workspace"
	echo
}

build_fat_img() {
	FATSOURCEDIR=$1
	FATIMG=$2

	echo $FATSOURCEDIR $FATIMG

	# Calculate the size required for the final image including the
	# data and filesystem overhead.
	# Sectors: 512 bytes
	# Blocks: 1024 bytes

	# Determine the sector count just for the data
	SECTORS=$(expr $(du --apparent-size -ks ${FATSOURCEDIR} | cut -f 1) \* 2)

	# Account for the filesystem overhead.
	# 32 bytes per dir entry
	DIR_BYTES=$(expr $(find ${FATSOURCEDIR} | tail -n +2 | wc -l) \* 32)
	# 32 bytes for every end-of-directory dir entry
	DIR_BYTES=$(expr $DIR_BYTES + $(expr $(find ${FATSOURCEDIR} -type d | tail -n +2 | wc -l) \* 32))
	# 4 bytes per FAT entry per sector of data
	FAT_BYTES=$(expr $SECTORS \* 4)
	# 4 bytes per FAT entry per end-of-cluster list
	FAT_BYTES=$(expr $FAT_BYTES + $(expr $(find ${FATSOURCEDIR} -type d | tail -n +2 | wc -l) \* 4))

	# Use a ceiling function to determine FS overhead in sectors
	DIR_SECTORS=$(expr $(expr $DIR_BYTES + 511) / 512)
	# There are two FATs on the image
	FAT_SECTORS=$(expr $(expr $(expr $FAT_BYTES + 511) / 512) \* 2)
	SECTORS=$(expr $SECTORS + $(expr $DIR_SECTORS + $FAT_SECTORS))

	# Determine the final size in blocks accounting for some padding
	BLOCKS=$(expr $(expr $SECTORS / 2) + ${BOOTIMG_EXTRA_SPACE})

	# mkfs.vfat will sometimes use FAT16 when it is not appropriate,
	# resulting in a boot failure. Use FAT32 for images larger
	# than 512MB, otherwise let mkfs.vfat decide.
	if [ $(expr $BLOCKS / 1024) -gt 512 ]; then
		FATSIZE="-F 32"
	fi

	# Delete any previous image.
	if [ -e ${FATIMG} ]; then
		rm ${FATIMG} -f
	fi

	mkfs.vfat ${FATSIZE} -n ${BOOTIMG_VOLUME_ID} ${MKFSVFAT_EXTRAOPTS} -C ${FATIMG} ${BLOCKS}

	# Copy FATSOURCEDIR recursively into the image file directly
	mcopy -i ${FATIMG} -s ${FATSOURCEDIR}/* ::/
}

do_dtb_package()
{
	mkdir -p ${TOP_DIR}/rubikpi/tools/pack/dtb_temp/dtb

	mkdir -p ${TOP_DIR}/rubikpi/output/pack

	cp ${TOP_DIR}/arch/arm64/boot/dts/qcom/rubikpi3-6490.dtb ${TOP_DIR}/rubikpi/tools/pack/dtb_temp/dtb/combined-dtb.dtb

	build_fat_img ${TOP_DIR}/rubikpi/tools/pack/dtb_temp/dtb ${TOP_DIR}/rubikpi/output/pack/dtb.bin

	rm ${TOP_DIR}/rubikpi/tools/pack/dtb_temp -rf
}

# DEFAULT_CMDLINE="initrd=\ostree\poky-960324eb402e612cd2ddd5c3b64db972337059114f4354eb95976f59a0ec3922\initramfs-6.6.52-qli-1.3-ver.1.1.img \
# 				root=/dev/disk/by-partlabel/system rw rootwait \
# 				console=ttyMSM0,115200n8 earlycon qcom_geni_serial.con_enabled=1 \
# 				kernel.sched_pelt_multiplier=4 \
# 				mem_sleep_default=s2idle"

DEFAULT_CMDLINE="root=/dev/disk/by-partlabel/system rw rootwait console=ttyMSM0,115200n8 earlycon qcom_geni_serial.con_enabled=1 kernel.sched_pelt_multiplier=4 mem_sleep_default=s2idle"


do_image_package()
{
	mkdir -p ${TOP_DIR}/rubikpi/tools/pack/image_temp
	mkdir -p ${TOP_DIR}/rubikpi/tools/pack/image_temp/mnt
	mkdir -p ${TOP_DIR}/rubikpi/output/pack

	cp ${TOP_DIR}/arch/arm64/boot/Image ${TOP_DIR}/rubikpi/tools/pack/image_temp

	python3 ${TOP_DIR}/rubikpi/tools/pack/ukify build \
		--efi-arch=aa64 \
		--stub="${TOP_DIR}/rubikpi/tools/pack/linuxaa64.efi.stub" \
		--linux="${TOP_DIR}/rubikpi/tools/pack/image_temp/Image" \
		--initrd="${TOP_DIR}/rubikpi/tools/pack/initramfs-ostree-image-qcm6490-idp.cpio.gz" \
		--cmdline="${DEFAULT_CMDLINE}" \
		--output="${TOP_DIR}/rubikpi/tools/pack/image_temp/linux-qcm6490-idp.efi"

	cp ${TOP_DIR}/rubikpi/tools/pack/efi.bin ${TOP_DIR}/rubikpi/tools/pack/image_temp
	sudo mount ${TOP_DIR}/rubikpi/tools/pack/image_temp/efi.bin ${TOP_DIR}/rubikpi/tools/pack/image_temp/mnt --options rw

	sudo cp ${TOP_DIR}/rubikpi/tools/pack/image_temp/linux-qcm6490-idp.efi ${TOP_DIR}/rubikpi/tools/pack/image_temp/mnt/ostree/poky-*/vmlinuz-6.6.90
	sudo umount ${TOP_DIR}/rubikpi/tools/pack/image_temp/mnt
	sudo cp ${TOP_DIR}/rubikpi/tools/pack/image_temp/efi.bin ${TOP_DIR}/rubikpi/output/pack

	rm ${TOP_DIR}/rubikpi/tools/pack/image_temp -rf
}

kernel_conf_variable() {
	sed -e "/CONFIG_$1[ =]/d;" -i ${TOP_DIR}/.config
	if test "$2" = "n"
	then
		echo "# CONFIG_$1 is not set" >> ${TOP_DIR}/.config
	else
		echo "CONFIG_$1=$2" >> ${TOP_DIR}/.config
	fi
}

do_merge_config()
{
	cp ${CONFIG_FILE_DIR}/${KERNEL_CONFIG} .config

	kernel_conf_variable LOCALVERSION "\"\""
	kernel_conf_variable LOCALVERSION_AUTO n

	scripts/kconfig/merge_config.sh -m -r -O ${TOP_DIR} ${TOP_DIR}/.config ${KERNEL_CONFIG_FRAGMENTS} 1>&2

	mv .config ${CONFIG_FILE_DIR}/rubikpi3_defconfig
	make ARCH=arm64 rubikpi3_defconfig

	rm ${CONFIG_FILE_DIR}/rubikpi3_defconfig
}

do_build_all()
{
	if [ ! -e "${TOP_DIR}/.config" ]; then
		do_merge_config
	fi

	make ARCH=arm64 CROSS_COMPILE=aarch64-qcom-linux- LOCALVERSION="" dir-pkg INSTALL_MOD_STRIP=1 -j`nproc`
	do_build_dtb
}

do_build_dtb()
{
	if [ ! -e "${TOP_DIR}/.config" ]; then
		do_merge_config
	fi

	# make rubikpi3.dtb
	DTC_FLAGS="-@ " make ARCH=arm64 CROSS_COMPILE=aarch64-qcom-linux- LOCALVERSION="" -j`nproc` qcom/rubikpi3.dtb

	# make qcm6490-graphics.dtbo
	make -C arch/arm64/boot/dts/qcom/graphics-devicetree \
			-j`nproc` \
			CC=aarch64-qcom-linux-gcc \
			DTC=${TOP_DIR}/scripts/dtc/dtc \
			KERNEL_INCLUDE=$KERNEL_INCLUDE \
			qcm6490-graphics

	# make qcm6490-display.dtbo
	# Default use of upstream static display devicetree
	# make -C arch/arm64/boot/dts/qcom/display-devicetree \
	# 		-j`nproc` \
	# 		CC=aarch64-qcom-linux-gcc \
	# 		DTC=${TOP_DIR}/scripts/dtc/dtc \
	# 		KERNEL_INCLUDE=$KERNEL_INCLUDE \
	# 		qcm6490-display

	# make qcm6490-camera-idp.dtbo
	make -C arch/arm64/boot/dts/qcom/camera-devicetree \
			-j`nproc` \
			CC=aarch64-qcom-linux-gcc \
			DTC=${TOP_DIR}/scripts/dtc/dtc \
			KERNEL_INCLUDE=$KERNEL_INCLUDE \
			qcm6490-camera-idp

	# make qcm6490-video.dtbo
	make -C arch/arm64/boot/dts/qcom/video-devicetree \
			-j`nproc` \
			CC=aarch64-qcom-linux-gcc \
			DTC=${TOP_DIR}/scripts/dtc/dtc \
			KERNEL_INCLUDE=$KERNEL_INCLUDE \
			qcm6490-video

	# make rubikpi3-overlay.dtbo
	make -C arch/arm64/boot/dts/thundercomm/rubikpi3 \
			-j`nproc` \
			CC=aarch64-qcom-linux-gcc \
			DTC=${TOP_DIR}/scripts/dtc/dtc \
			KERNEL_INCLUDE=$KERNEL_INCLUDE \
			rubikpi3-overlay

	# make rubikpi3-6490.dtb
	# Default use of upstream static display devicetree
	# arch/arm64/boot/dts/qcom/display-devicetree/display/qcm6490-display.dtbo \
	${TOP_DIR}/scripts/dtc/fdtoverlay -v -i \
		arch/arm64/boot/dts/qcom/rubikpi3.dtb \
		arch/arm64/boot/dts/qcom/graphics-devicetree/gpu/qcm6490-graphics.dtbo \
		arch/arm64/boot/dts/qcom/camera-devicetree/qcm6490-camera-idp.dtbo \
		arch/arm64/boot/dts/qcom/video-devicetree/qcm6490-video.dtbo \
		arch/arm64/boot/dts/thundercomm/rubikpi3/rubikpi3-overlay.dtbo \
		-o arch/arm64/boot/dts/qcom/rubikpi3-6490.dtb
}

do_clean()
{
	make clean
	if [ -e .config ]; then
		rm .config
	fi
}

do_before_compilation()
{
	local src_selinux="${TOP_DIR}/rubikpi/tools/pack/config/selinux.cfg"
	local dst_selinux="${TOP_DIR}/arch/arm64/configs/selinux.cfg"
	local src_smack="${TOP_DIR}/rubikpi/tools/pack/config/smack.cfg"
	local dst_smack="${TOP_DIR}/arch/arm64/configs/smack.cfg"
	local src_techpack_makefile="${TOP_DIR}/rubikpi/tools/pack/makefile/Makefile"
	local dst_techpack_makefile="${TOP_DIR}/techpack/Makefile"
	local src_msm_camera="${TOP_DIR}/rubikpi/tools/pack/include/msm-camera.h"
	local dst_msm_camera="${TOP_DIR}/include/dt-bindings/msm-camera.h"

	if [ ! -f "$dst_selinux" ]; then
		cp -v "$src_selinux" "$dst_selinux"
	fi

	if [ ! -f "$dst_smack" ]; then
		cp -v "$src_smack" "$dst_smack"
	fi

	if [ ! -f "$dst_techpack_makefile" ]; then
		cp -v "$src_techpack_makefile" "$dst_techpack_makefile"
	fi

	if [ ! -f "$dst_msm_camera" ]; then
		cp -v "$src_msm_camera" "$dst_msm_camera"
	fi

	local kbuild_file="${TOP_DIR}/techpack/display/msm/Kbuild"
	local timestamp_pattern='^# CDEFINES += -DBUILD_TIMESTAMP='
	if ! grep -qE "$timestamp_pattern" "$kbuild_file"; then
		sed -i '/DBUILD_TIMESTAMP/c\# CDEFINES += -DBUILD_TIMESTAMP=\"$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')\"' "$kbuild_file"
	fi

	# Default use of upstream static display devicetree
	# local techpack_kbuild="${TOP_DIR}/Kbuild"
	# local techpack_line='obj-y			+= techpack/'
	# if ! sed -n '99p' "$techpack_kbuild" | grep -qF "$techpack_line"; then
	# 	sed -i "99i$techpack_line" "$techpack_kbuild"
	# fi

	local target_file="${TOP_DIR}/arch/arm64/boot/dts/qcom/Makefile"
	if ! grep -q '^ifdef RUBIKPI_DTB_BUILD_ALL' "$target_file"; then
		sed -i '2iifdef RUBIKPI_DTB_BUILD_ALL' "$target_file"
	fi
	local marker_line=$(grep -n '# rubikpi' "$target_file" | cut -d: -f1)
	if [ -z "$marker_line" ]; then
		echo "error: no '# rubikpi' tag found"
		exit 1
	fi
	local ifdef_line=2
	local end_range=$((marker_line - 1))
	if ! sed -n "${ifdef_line},${end_range}p" "$target_file" | grep -q '^endif'; then
		sed -i "${end_range}iendif" "$target_file"
	fi
}

# ========================== Start ========================================
do_dtb_package_flag=0
do_image_package_flag=0
do_build_all_flag=0
do_build_dtb_flag=0
do_clean_flag=0
do_merge_config_flag=0

do_before_compilation
if [ "$1" != "" ]; then
	while true; do
		case "$1" in
			-h|--help)              usage; exit 0;;
			-dp|--dtb_package)      do_dtb_package_flag=1 ;;
			-ip|--image_package)    do_image_package_flag=1 ;;
			-a|--build_all)         do_build_all_flag=1 ;;
			-d|--build_dts)         do_build_dtb_flag=1 ;;
			-gc|--generate_config)   do_merge_config_flag=1 ;;
			-c|--clean)   do_clean_flag=1 ;;
		esac
		shift

		if [ "$1" = "" ]; then
			break
		fi
	done

	if [ "$do_clean_flag" -eq "1" ]; then
		do_clean
	fi

	if [ "$do_merge_config_flag" -eq "1" ]; then
		do_merge_config
	fi

	if [ ${do_build_all_flag} -eq "1" ]; then
		do_build_all
	fi

	if [ ${do_build_dtb_flag} -eq "1" ]; then
		do_build_dtb
	fi

	if [ ${do_dtb_package_flag} -eq "1" ]; then
		do_dtb_package
	fi

	if [ ${do_image_package_flag} -eq "1" ]; then
		do_image_package
	fi
else
	do_build_all
	do_dtb_package
	do_image_package
fi


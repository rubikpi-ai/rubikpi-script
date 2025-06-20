#!/bin/bash
# Author: Zhao Hongyang <hongyang.zhao@thundersoft.com>
# Date: 2025-03-13
# Copyright (c) 2025, Thundercomm All rights reserved.
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

meta_dir=`pwd`

assert() {
	if [ ${PIPESTATUS[0]} -ne 0 ]; then
		exit 1;
	fi
}

usage() {
	echo "\033[1;37mUsage:\033[0m"
	echo "  bash $0 [options]"
	echo
	echo "\033[1;37mOptions:\033[0m"
	echo "\033[1;37m  -h, --help\033[0m              display this help message"
	echo "\033[1;37m  -a, --build_all\033[0m         Compile Yocto project"
	echo "\033[1;37m  -l, --log\033[0m               Save the logs to file"
	echo "\033[1;37m  -c, --clean\033[0m             Clean up workspace"
	echo "\033[1;37m  -p, --zip_flat_build\033[0m    Package the flat build"
	echo
}

PRODUCT=""
ProjectName="RUBIKPi"
HardWareVersion="xx"
SoftWareVersion="QLI_1.3"
Buildtime=`date +%Y%m%d.%H%M%S`
RUBIKPI_ID="${ProjectName}_${HardWareVersion}_${SoftWareVersion}"
STORAGE="ufs"

LOGDIR="${meta_dir}/build_log/BuildLog_${RUBIKPI_ID}.${Buildtime}"
DEF_LOG_FILE=/dev/null
log_file=$DEF_LOG_FILE

do_log() {
	if [ "$1" = "1" ]; then
		if [ ! -d $LOGDIR ]; then
			mkdir -p $LOGDIR
		fi

		log_file=$LOGDIR/$2
	else
		log_file=$DEF_LOG_FILE
	fi
}

do_build_all() {
	echo "`date +%Y%m%d_%H:%M:%S` RUBIKPI_ID:${RUBIKPI_ID}" 2>&1 | tee -a $log_file
	cd ${meta_dir}
	echo "${meta_dir}" 2>&1 | tee -a $log_file

	echo "export EXTRALAYERS="meta-qcom-qim-sdk"" 2>&1 | tee -a $log_file
	export EXTRALAYERS="meta-qcom-qim-product-sdk"

	echo "MACHINE=qcm6490-idp" 2>&1 | tee -a $log_file
	export MACHINE=qcm6490-idp


	echo " DISTRO=qcom-wayland" 2>&1 | tee -a $log_file
	export DISTRO=qcom-wayland

	echo "FWZIP_PATH="${meta_dir}/src/vendor/thundercomm/prebuilt/BP-BINs"" 2>&1 | tee -a $log_file
	export FWZIP_PATH="${meta_dir}/src/vendor/thundercomm/prebuilt/BP-BINs"

	if [ "${PRODUCT}" == "Qualcomm" ]; then
		echo "source setup-environment" 2>&1 | tee -a $log_file
		source ${meta_dir}/setup-environment
	else
		echo "source setup-environment_RUBIKPi" 2>&1 | tee -a $log_file
		source ${meta_dir}/setup-environment_RUBIKPi
	fi

	echo "BB_ENV_PASSTHROUGH_ADDITIONS" 2>&1 | tee -a $log_file
	export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_PASSTHROUGH_ADDITIONS FWZIP_PATH CUST_ID"

	echo "bitbake qcom-multimedia-image" 2>&1 | tee -a $log_file
	bitbake qcom-multimedia-image 2>&1 | tee -a $log_file
	assert

	echo "bitbake qcom-qim-product-sdk" 2>&1 | tee -a $log_file
	bitbake qcom-qim-product-sdk
	assert
}

do_clean() {
	cd ${meta_dir}

	rm build-qcom-wayland -rf
	rm sstate-cache -rf
	rm build_log -rf
}

copy_files() {
	FILELIST=$1
	TARGETDIR=$2

	if [ -d $TARGETDIR ]; then
		echo "rm -fr $TARGETDIR" 2>&1 | tee -a $log_file
		rm -fr $TARGETDIR
	fi

	echo "mkdir -p $TARGETDIR" 2>&1 | tee -a $log_file
	mkdir -p $TARGETDIR

	cd ${meta_dir}

	for f in ${FILELIST[*]}; do
		echo "cp -Lrpf --parents $f $TARGETDIR" 2>&1 | tee -a $log_file
		cp -Lrpf $f $TARGETDIR
		assert
	done
	assert
}

BIN_FILELIST=($meta_dir/build-qcom-wayland/tmp-glibc/deploy/images/qcm6490-idp/qcom-multimedia-image/*)
RUBIKPIOUT=${meta_dir}/rubikpi/output
FLATDIRNAME=FlatBuild_$RUBIKPI_ID.${Buildtime}

zip_package() {
	cd $RUBIKPIOUT

	echo "zip -r $FLATDIRNAME.zip $FLATDIRNAME" 2>&1 | tee -a $log_file
	zip -r $FLATDIRNAME.zip $FLATDIRNAME
	assert
}

do_flat_build() {
	copy_files "${BIN_FILELIST[*]}" $RUBIKPIOUT/$FLATDIRNAME/$STORAGE
	zip_package
}


# ========================== Start ========================================
LOGFILE=rubikpi_build.log
do_log_flag=0
do_build_all_flag=0
do_clean_flag=0
do_flat_build_flag=0

if [ "$1" != "" ]; then
	while true; do
		case "$1" in
			-h|--help)              usage; exit 0;;
			-a|--build_all)         do_build_all_flag=1 ;;
			-l|--log)               do_log_flag=1;;
			-c|--clean)             do_clean_flag=1 ;;
			-p|--zip_flat_build)    do_flat_build_flag=1 ;;
		esac
		shift

		if [ "$1" = "" ]; then
			break
		fi
	done

	if [ ${do_clean_flag} -eq "1" ]; then
		do_clean
	fi

	if [ ${do_log_flag} -eq "1" ]; then
		do_log $do_log_flag $LOGFILE
	fi

	if [ ${do_build_all_flag} -eq "1" ]; then
		do_build_all
	fi

	if [ ${do_flat_build_flag} -eq "1" ]; then
		do_flat_build
	fi
else
	do_build_all
fi


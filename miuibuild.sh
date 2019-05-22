#!/bin/bash
kernel_dir=$PWD
export V="$(date +'%d%m-%H%M')"
export CONFIG_FILE="octopus_defconfig"
date=`date +"%Y%m%d-%H%M"`
DATE=`date +"%Y%m%d"`

BUILD_START=$(date +"%s")
# Coloring
blue='\033[0;34m'
cyan='\033[0;36m'
purple='\e[0;35m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'


export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="octo21" # Build Host
export KBUILD_BUILD_HOST="lineageOS" # Build Name
export CROSS_COMPILE="/home/octo/Kernel/aarch64-linux-android/bin/aarch64-unknown-linux-android-"
export PATH=$PATH:${TOOL_CHAIN_PATH}
export out_dir="${kernel_dir}/out/"
export builddir="${kernel_dir}/Builds"
export ANY_KERNEL2_DIR="/home/octo/Kernel/octopus_miui_mido/AnyKernel2"
export ZIP_NAME="miui-octopus-${DATE}.zip"
export IMAGE="${out_dir}arch/arm64/boot/Image.gz-dtb";
export STRIP_KO="/home/octo/Kernel/aarch64-linux-android/aarch64-unknown-linux-android/bin/strip"
JOBS="-j$(nproc --all)"
cd $kernel_dir

make_defconfig() {
	make O=${out_dir} $CONFIG_FILE
}

compile() {
	make \
	O=${out_dir} \
	$JOBS
}

zipit () {
    if [[ ! -f "${IMAGE}" ]]; then
        echo -e "Build failed :P";
        exit 1;
    else
        echo -e "Build Succesful!";
    fi
    echo "**** Copying Image ****"
    cp ${out_dir}arch/arm64/boot/Image.gz-dtb ${ANY_KERNEL2_DIR}/

    echo "**** Copying Modules for MIUI ROM ****"
    find ${out_dir} -name '*.ko' -exec ${STRIP_KO} -g {}  \;
    find ${out_dir} -name '*.ko' -exec cp {} ${ANY_KERNEL2_DIR}/modules/system/lib/modules/ \; 
    cp ${ANY_KERNEL2_DIR}/modules/system/lib/modules/wlan.ko ${ANY_KERNEL2_DIR}/modules/system/lib/modules/pronto/pronto_wlan.ko
    cd ${ANY_KERNEL2_DIR}/

    echo "**** Zipping ****"
    zip -r9 ${ZIP_NAME} * -x README ${ZIP_NAME}
    rm -rf ${kernel_dir}/build/${ZIP_NAME}
    mv ${ANY_KERNEL2_DIR}/${ZIP_NAME} ${kernel_dir}/build/${ZIP_NAME}
}

make_defconfig
compile
zipit
cd ${kernel_dir}

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

